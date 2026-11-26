#!/usr/bin/env python3
"""Generate DanceProgressionJournal.xcodeproj from the source tree.

The build VM has no Xcode, so the project file is generated from the file
list on disk. Run from the repo root:

    python3 tools/generate_xcodeproj.py

It scans DanceProgressionJournal/**/*.swift and
DanceProgressionJournalTests/**/*.swift, plus Info.plist and
Assets.xcassets, and writes DanceProgressionJournal.xcodeproj with an app
target and a unit test target. Re run it whenever files are added or
removed. Hand edits to project.pbxproj are overwritten.
"""

import hashlib
import json
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
APP_DIR = REPO / "DanceProgressionJournal"
TEST_DIR = REPO / "DanceProgressionJournalTests"
OUT = REPO / "DanceProgressionJournal.xcodeproj"


def pbx_id(key: str) -> str:
    return hashlib.md5(key.encode()).hexdigest()[:24].upper()


def q(value: str) -> str:
    return '"' + value.replace('"', '\\"') + '"'


class Section:
    def __init__(self, name: str):
        self.name = name
        self.entries: list[str] = []

    def add(self, text: str) -> None:
        self.entries.append(text)


def file_ref(path: Path, kind: str) -> tuple[str, str]:
    # NOTE: the emitted path must be the bare file name, not the path
    # relative to the repo root. A PBXFileReference with sourceTree
    # "<group>" resolves relative to its containing group, and every
    # group already carries its directory in its own path (app group
    # "DanceProgressionJournal", subgroups "DesignSystem",
    # "Views/Journal", ...). A repo relative path here resolves to a
    # doubled path that does not exist on disk, and the build fails
    # with "No such file or directory" at the asset catalog step.
    # The id still hashes the repo relative path so ids stay stable.
    rel = path.relative_to(REPO).as_posix()
    fid = pbx_id("fileref:" + rel)
    if kind == "swift":
        last = "sourcecode.swift"
    elif kind == "plist":
        last = "text.plist.xml"
    elif kind == "xcassets":
        last = "folder.assetcatalog"
    elif kind == "app":
        last = "wrapper.application"
    elif kind == "xctest":
        last = "wrapper.cfbundle"
    else:
        last = "text"
    explicit = "wrapper.application" if kind == "app" else None
    entry = (
        f"\t\t{fid} /* {path.name} */ = {{isa = PBXFileReference; "
        f"lastKnownFileType = {last}; name = {q(path.name)}; "
        f"path = {q(path.name)}; sourceTree = \"<group>\"; }};"
    )
    return fid, entry


def main() -> int:
    app_swift = sorted(APP_DIR.rglob("*.swift"))
    test_swift = sorted(TEST_DIR.rglob("*.swift"))
    info_plist = APP_DIR / "Info.plist"
    assets = APP_DIR / "Assets.xcassets"

    build_files = Section("PBXBuildFile")
    file_refs = Section("PBXFileReference")
    groups = Section("PBXGroup")
    sources_app: list[str] = []
    sources_test: list[str] = []
    resources_app: list[str] = []

    # Group hierarchy: mirror the folders on disk.
    group_defs: dict[str, list[str]] = {}
    group_ids: dict[str, str] = {}

    def group_id(name: str) -> str:
        if name not in group_ids:
            group_ids[name] = pbx_id("group:" + name)
        return group_ids[name]

    # App source files, grouped by parent folder relative to APP_DIR.
    app_file_ids: dict[str, list[str]] = {}
    for path in app_swift:
        rel = path.relative_to(APP_DIR)
        parent = str(rel.parent) if str(rel.parent) != "." else ""
        fid, entry = file_ref(path, "swift")
        file_refs.add(entry)
        bf = pbx_id("buildfile:" + path.relative_to(REPO).as_posix())
        build_files.add(
            f"\t\t{bf} /* {path.name} in Sources */ = {{isa = PBXBuildFile; fileRef = {fid} /* {path.name} */; }};"
        )
        sources_app.append(bf)
        app_file_ids.setdefault(parent, []).append(fid)

    # Test source files.
    test_file_ids: list[str] = []
    for path in test_swift:
        rel = path.relative_to(TEST_DIR)
        fid, entry = file_ref(path, "swift")
        file_refs.add(entry)
        bf = pbx_id("buildfile:" + path.relative_to(REPO).as_posix())
        build_files.add(
            f"\t\t{bf} /* {path.name} in Sources */ = {{isa = PBXBuildFile; fileRef = {fid} /* {path.name} */; }};"
        )
        sources_test.append(bf)
        test_file_ids.append(fid)

    # Info.plist and asset catalog.
    plist_id, plist_entry = file_ref(info_plist, "plist")
    file_refs.add(plist_entry)
    assets_id, assets_entry = file_ref(assets, "xcassets")
    file_refs.add(assets_entry)
    assets_bf = pbx_id("buildfile:Assets.xcassets")
    build_files.add(
        f"\t\t{assets_bf} /* Assets.xcassets in Resources */ = {{isa = PBXBuildFile; fileRef = {assets_id} /* Assets.xcassets */; }};"
    )
    resources_app.append(assets_bf)

    # Product references.
    app_product_id, app_product_entry = file_ref(
        REPO / "DanceProgressionJournal.app", "app"
    )
    test_product_id, test_product_entry = file_ref(
        REPO / "DanceProgressionJournalTests.xctest", "xctest"
    )
    # Products live in the Products group, path is just the file name.
    app_product_entry = app_product_entry.replace(
        f"path = {q('DanceProgressionJournal.app')}",
        "path = DanceProgressionJournal.app",
    )
    test_product_entry = test_product_entry.replace(
        f"path = {q('DanceProgressionJournalTests.xctest')}",
        "path = DanceProgressionJournalTests.xctest",
    )
    file_refs.add(app_product_entry)
    file_refs.add(test_product_entry)

    # Groups.
    main_group_id = group_id("main")
    app_group_id = group_id("DanceProgressionJournal")
    test_group_id = group_id("DanceProgressionJournalTests")
    products_group_id = group_id("Products")

    # Sub groups inside the app group, one per folder.
    subgroup_ids: dict[str, str] = {}
    subgroup_children: dict[str, list[str]] = {}
    for parent, fids in sorted(app_file_ids.items()):
        if parent == "":
            subgroup_children[""] = fids
            continue
        gid = group_id("app:" + parent)
        subgroup_ids[parent] = gid
        subgroup_children[parent] = fids
        groups.add(
            f"\t\t{gid} /* {parent} */ = {{isa = PBXGroup; children = (\n"
            + "".join(f"\t\t\t\t{fid} /* {Path(fid).name} */,\n" for fid in fids)
            + "\t\t\t); name = "
            + q(parent.split("/")[-1])
            + "; path = "
            + q(parent)
            + "; sourceTree = \"<group>\"; };"
        )

    # The file names in group children need real names, so rebuild the
    # subgroup entries with names from the file list.
    groups.entries = [e for e in groups.entries if "/*" not in e or True]
    # Rebuild subgroup entries properly:
    groups.entries = []
    for parent in sorted(subgroup_ids):
        gid = subgroup_ids[parent]
        fids = subgroup_children[parent]
        names = []
        for path in app_swift:
            rel = path.relative_to(APP_DIR)
            if str(rel.parent) == parent:
                names.append((path.name, pbx_id("fileref:" + path.relative_to(REPO).as_posix())))
        children = "".join(
            f"\t\t\t\t{fid} /* {name} */,\n" for name, fid in names
        )
        groups.add(
            f"\t\t{gid} /* {parent.split('/')[-1]} */ = {{isa = PBXGroup; children = (\n"
            f"{children}\t\t\t); name = {q(parent.split('/')[-1])}; path = {q(parent)}; sourceTree = \"<group>\"; }};"
        )

    # App group children: root files, subgroups, Info.plist, Assets.
    root_files = app_file_ids.get("", [])
    root_children = ""
    for path in app_swift:
        rel = path.relative_to(APP_DIR)
        if str(rel.parent) == ".":
            fid = pbx_id("fileref:" + path.relative_to(REPO).as_posix())
            root_children += f"\t\t\t\t{fid} /* {path.name} */,\n"
    subgroup_children_text = "".join(
        f"\t\t\t\t{subgroup_ids[p]} /* {p.split('/')[-1]} */,\n"
        for p in sorted(subgroup_ids)
    )
    groups.add(
        f"\t\t{app_group_id} /* DanceProgressionJournal */ = {{isa = PBXGroup; children = (\n"
        f"{root_children}{subgroup_children_text}"
        f"\t\t\t\t{plist_id} /* Info.plist */,\n"
        f"\t\t\t\t{assets_id} /* Assets.xcassets */,\n"
        f"\t\t\t); path = DanceProgressionJournal; sourceTree = \"<group>\"; }};"
    )

    test_children = "".join(
        f"\t\t\t\t{fid} /* {p.name} */,\n"
        for fid, p in zip(test_file_ids, test_swift)
    )
    groups.add(
        f"\t\t{test_group_id} /* DanceProgressionJournalTests */ = {{isa = PBXGroup; children = (\n"
        f"{test_children}\t\t\t); path = DanceProgressionJournalTests; sourceTree = \"<group>\"; }};"
    )
    groups.add(
        f"\t\t{products_group_id} /* Products */ = {{isa = PBXGroup; children = (\n"
        f"\t\t\t\t{app_product_id} /* DanceProgressionJournal.app */,\n"
        f"\t\t\t\t{test_product_id} /* DanceProgressionJournalTests.xctest */,\n"
        f"\t\t\t); name = Products; sourceTree = \"<group>\"; }};"
    )
    groups.add(
        f"\t\t{main_group_id} = {{isa = PBXGroup; children = (\n"
        f"\t\t\t\t{app_group_id} /* DanceProgressionJournal */,\n"
        f"\t\t\t\t{test_group_id} /* DanceProgressionJournalTests */,\n"
        f"\t\t\t\t{products_group_id} /* Products */,\n"
        f"\t\t\t); sourceTree = \"<group>\"; }};"
    )

    # Build phases.
    sources_app_id = pbx_id("phase:sources:app")
    sources_test_id = pbx_id("phase:sources:test")
    resources_app_id = pbx_id("phase:resources:app")
    frameworks_app_id = pbx_id("phase:frameworks:app")
    frameworks_test_id = pbx_id("phase:frameworks:test")

    def phase_list(phase_id: str, kind: str, name: str, files: list[str], target_comment: str) -> str:
        files_text = "".join(f"\t\t\t\t{f} /* {name} */,\n" for f in files)
        return (
            f"\t\t{phase_id} /* {name} */ = {{isa = {kind}; buildActionMask = 2147483647; "
            f"files = (\n{files_text}\t\t\t); runOnlyForDeploymentPostprocessing = 0; }};"
        )

    sources_section = Section("PBXSourcesBuildPhase")
    sources_section.add(phase_list(sources_app_id, "PBXSourcesBuildPhase", "Sources", sources_app, "app"))
    sources_section.add(phase_list(sources_test_id, "PBXSourcesBuildPhase", "Sources", sources_test, "test"))
    resources_section = Section("PBXResourcesBuildPhase")
    resources_section.add(phase_list(resources_app_id, "PBXResourcesBuildPhase", "Resources", resources_app, "app"))
    frameworks_section = Section("PBXFrameworksBuildPhase")
    frameworks_section.add(
        f"\t\t{frameworks_app_id} /* Frameworks */ = {{isa = PBXFrameworksBuildPhase; buildActionMask = 2147483647; files = (); runOnlyForDeploymentPostprocessing = 0; }};"
    )
    frameworks_section.add(
        f"\t\t{frameworks_test_id} /* Frameworks */ = {{isa = PBXFrameworksBuildPhase; buildActionMask = 2147483647; files = (); runOnlyForDeploymentPostprocessing = 0; }};"
    )

    # Targets.
    app_target_id = pbx_id("target:app")
    test_target_id = pbx_id("target:test")
    app_config_list = pbx_id("configlist:app")
    test_config_list = pbx_id("configlist:test")
    project_config_list = pbx_id("configlist:project")
    project_id = pbx_id("project")
    proxy_id = pbx_id("proxy:testdep")
    dependency_id = pbx_id("dependency:testdep")

    targets_section = Section("PBXNativeTarget")
    targets_section.add(
        f"\t\t{app_target_id} /* DanceProgressionJournal */ = {{isa = PBXNativeTarget; "
        f"buildConfigurationList = {app_config_list} /* Build configuration list for PBXNativeTarget \"DanceProgressionJournal\" */; "
        f"buildPhases = (\n"
        f"\t\t\t\t{sources_app_id} /* Sources */,\n"
        f"\t\t\t\t{frameworks_app_id} /* Frameworks */,\n"
        f"\t\t\t\t{resources_app_id} /* Resources */,\n"
        f"\t\t\t); buildRules = (); dependencies = (); name = DanceProgressionJournal; "
        f"productName = DanceProgressionJournal; productReference = {app_product_id} /* DanceProgressionJournal.app */; "
        f"productType = \"com.apple.product-type.application\"; }};"
    )
    targets_section.add(
        f"\t\t{test_target_id} /* DanceProgressionJournalTests */ = {{isa = PBXNativeTarget; "
        f"buildConfigurationList = {test_config_list} /* Build configuration list for PBXNativeTarget \"DanceProgressionJournalTests\" */; "
        f"buildPhases = (\n"
        f"\t\t\t\t{sources_test_id} /* Sources */,\n"
        f"\t\t\t\t{frameworks_test_id} /* Frameworks */,\n"
        f"\t\t\t); buildRules = (); dependencies = (\n"
        f"\t\t\t\t{dependency_id} /* PBXTargetDependency */,\n"
        f"\t\t\t); name = DanceProgressionJournalTests; "
        f"productName = DanceProgressionJournalTests; productReference = {test_product_id} /* DanceProgressionJournalTests.xctest */; "
        f"productType = \"com.apple.product-type.bundle.unit-test\"; }};"
    )

    proxy_section = Section("PBXContainerItemProxy")
    proxy_section.add(
        f"\t\t{proxy_id} /* PBXContainerItemProxy */ = {{isa = PBXContainerItemProxy; "
        f"containerPortal = {project_id} /* Project object */; proxyType = 1; "
        f"remoteGlobalIDString = {app_target_id}; remoteInfo = DanceProgressionJournal; }};"
    )
    dependency_section = Section("PBXTargetDependency")
    dependency_section.add(
        f"\t\t{dependency_id} /* PBXTargetDependency */ = {{isa = PBXTargetDependency; "
        f"target = {app_target_id} /* DanceProgressionJournal */; targetProxy = {proxy_id} /* PBXContainerItemProxy */; }};"
    )

    # Build configurations.
    configs_section = Section("XCBuildConfiguration")
    config_lists_section = Section("XCConfigurationList")

    project_debug = pbx_id("config:project:debug")
    project_release = pbx_id("config:project:release")
    app_debug = pbx_id("config:app:debug")
    app_release = pbx_id("config:app:release")
    test_debug = pbx_id("config:test:debug")
    test_release = pbx_id("config:test:release")

    def settings_block(settings: dict[str, str]) -> str:
        lines = []
        for key in sorted(settings):
            value = settings[key]
            if value.startswith("(") or value.startswith('"'):
                lines.append(f"\t\t\t\t{key} = {value};")
            else:
                lines.append(f"\t\t\t\t{key} = {q(value)};")
        return "buildSettings = {\n" + "\n".join(lines) + "\n\t\t\t};"

    def config(cid: str, name: str, settings: dict[str, str]) -> str:
        return (
            f"\t\t{cid} /* {name} */ = {{isa = XCBuildConfiguration; "
            f"{settings_block(settings)} name = {name}; }};"
        )

    project_common = {
        "ALWAYS_SEARCH_USER_PATHS": "NO",
        "CLANG_ANALYZER_NONNULL": "YES",
        "CLANG_ANALYZER_NUMBER_OBJECT_CONVERSION": "YES_AGGRESSIVE",
        "CLANG_CXX_LANGUAGE_STANDARD": "gnu++20",
        "CLANG_ENABLE_MODULES": "YES",
        "CLANG_ENABLE_OBJC_ARC": "YES",
        "CLANG_ENABLE_OBJC_WEAK": "YES",
        "CLANG_WARN_BLOCK_CAPTURE_AUTORELEASING": "YES",
        "CLANG_WARN_BOOL_CONVERSION": "YES",
        "CLANG_WARN_COMMA": "YES",
        "CLANG_WARN_CONSTANT_CONVERSION": "YES",
        "CLANG_WARN_DEPRECATED_OBJC_IMPLEMENTATIONS": "YES",
        "CLANG_WARN_DIRECT_OBJC_ISA_USAGE": "YES_ERROR",
        "CLANG_WARN_DOCUMENTATION_COMMENTS": "YES",
        "CLANG_WARN_EMPTY_BODY": "YES",
        "CLANG_WARN_ENUM_CONVERSION": "YES",
        "CLANG_WARN_INFINITE_RECURSION": "YES",
        "CLANG_WARN_INT_CONVERSION": "YES",
        "CLANG_WARN_NON_LITERAL_NULL_CONVERSION": "YES",
        "CLANG_WARN_OBJC_IMPLICIT_RETAIN_SELF": "YES",
        "CLANG_WARN_OBJC_LITERAL_CONVERSION": "YES",
        "CLANG_WARN_OBJC_ROOT_CLASS": "YES_ERROR",
        "CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER": "YES",
        "CLANG_WARN_RANGE_LOOP_ANALYSIS": "YES",
        "CLANG_WARN_STRICT_PROTOTYPES": "YES",
        "CLANG_WARN_SUSPICIOUS_MOVE": "YES",
        "CLANG_WARN_UNGUARDED_AVAILABILITY": "YES_AGGRESSIVE",
        "CLANG_WARN_UNREACHABLE_CODE": "YES",
        "CLANG_WARN__DUPLICATE_METHOD_MATCH": "YES",
        "COPY_PHASE_STRIP": "NO",
        "ENABLE_STRICT_OBJC_MSGSEND": "YES",
        "GCC_C_LANGUAGE_STANDARD": "gnu17",
        "GCC_DYNAMIC_NO_PIC": "NO",
        "GCC_NO_COMMON_BLOCKS": "YES",
        "GCC_WARN_64_TO_32_BIT_CONVERSION": "YES",
        "GCC_WARN_ABOUT_RETURN_TYPE": "YES_ERROR",
        "GCC_WARN_UNDECLARED_SELECTOR": "YES",
        "GCC_WARN_UNINITIALIZED_AUTOS": "YES_AGGRESSIVE",
        "GCC_WARN_UNUSED_FUNCTION": "YES",
        "GCC_WARN_UNUSED_VARIABLE": "YES",
        "SDKROOT": "iphoneos",
    }
    project_debug_settings = dict(project_common)
    project_debug_settings.update({
        "DEBUG_INFORMATION_FORMAT": "dwarf",
        "ENABLE_TESTABILITY": "YES",
        "GCC_OPTIMIZATION_LEVEL": "0",
        "GCC_PREPROCESSOR_DEFINITIONS": '("DEBUG=1", "$(inherited)")',
        "MTL_ENABLE_DEBUG_INFO": "INCLUDE_SOURCE",
        "MTL_FAST_MATH": "YES",
        "ONLY_ACTIVE_ARCH": "YES",
        "SWIFT_ACTIVE_COMPILATION_CONDITIONS": "DEBUG",
        "SWIFT_OPTIMIZATION_LEVEL": "-Onone",
    })
    project_release_settings = dict(project_common)
    project_release_settings.update({
        "DEBUG_INFORMATION_FORMAT": "dwarf-with-dsym",
        "ENABLE_TESTABILITY": "NO",
        "GCC_OPTIMIZATION_LEVEL": "s",
        "MTL_ENABLE_DEBUG_INFO": "NO",
        "MTL_FAST_MATH": "YES",
        "SWIFT_COMPILATION_MODE": "wholemodule",
        "SWIFT_OPTIMIZATION_LEVEL": "-O",
    })
    configs_section.add(config(project_debug, "Debug", project_debug_settings))
    configs_section.add(config(project_release, "Release", project_release_settings))

    app_common = {
        "ASSETCATALOG_COMPILER_APPICON_NAME": "AppIcon",
        "ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME": "AccentColor",
        "CODE_SIGN_STYLE": "Automatic",
        "CURRENT_PROJECT_VERSION": "1",
        "DEFINES_MODULE": "YES",
        "ENABLE_PREVIEWS": "YES",
        "GENERATE_INFOPLIST_FILE": "NO",
        "INFOPLIST_FILE": "DanceProgressionJournal/Info.plist",
        "IPHONEOS_DEPLOYMENT_TARGET": "17.0",
        "LD_RUNPATH_SEARCH_PATHS": '"$(inherited) @executable_path/Frameworks"',
        "MARKETING_VERSION": "1.0.0",
        "PRODUCT_BUNDLE_IDENTIFIER": "com.codeair.danceprogressionjournal",
        "PRODUCT_NAME": "$(TARGET_NAME)",
        "SWIFT_VERSION": "6.0",
        "TARGETED_DEVICE_FAMILY": "1",
    }
    app_debug_settings = dict(app_common)
    app_debug_settings.update({
        "DEBUG_INFORMATION_FORMAT": "dwarf",
        "ENABLE_TESTABILITY": "YES",
        "SWIFT_ACTIVE_COMPILATION_CONDITIONS": "DEBUG",
        "SWIFT_OPTIMIZATION_LEVEL": "-Onone",
    })
    app_release_settings = dict(app_common)
    app_release_settings.update({
        "DEBUG_INFORMATION_FORMAT": "dwarf-with-dsym",
        "SWIFT_COMPILATION_MODE": "wholemodule",
        "SWIFT_OPTIMIZATION_LEVEL": "-O",
        "SWIFT_TREAT_WARNINGS_AS_ERRORS": "YES",
    })
    configs_section.add(config(app_debug, "Debug", app_debug_settings))
    configs_section.add(config(app_release, "Release", app_release_settings))

    test_common = {
        "BUNDLE_LOADER": "$(TEST_HOST)",
        "CODE_SIGN_STYLE": "Automatic",
        "CURRENT_PROJECT_VERSION": "1",
        "GENERATE_INFOPLIST_FILE": "YES",
        "IPHONEOS_DEPLOYMENT_TARGET": "17.0",
        "LD_RUNPATH_SEARCH_PATHS": '"$(inherited) @executable_path/Frameworks @loader_path/Frameworks"',
        "MARKETING_VERSION": "1.0.0",
        "PRODUCT_BUNDLE_IDENTIFIER": "com.codeair.danceprogressionjournal.tests",
        "PRODUCT_NAME": "$(TARGET_NAME)",
        "SWIFT_VERSION": "6.0",
        "TARGETED_DEVICE_FAMILY": "1",
        "TEST_HOST": "$(BUILT_PRODUCTS_DIR)/DanceProgressionJournal.app/DanceProgressionJournal",
    }
    test_debug_settings = dict(test_common)
    test_debug_settings.update({
        "DEBUG_INFORMATION_FORMAT": "dwarf",
        "ENABLE_TESTABILITY": "YES",
        "SWIFT_ACTIVE_COMPILATION_CONDITIONS": "DEBUG",
        "SWIFT_OPTIMIZATION_LEVEL": "-Onone",
    })
    test_release_settings = dict(test_common)
    test_release_settings.update({
        "DEBUG_INFORMATION_FORMAT": "dwarf-with-dsym",
        "SWIFT_COMPILATION_MODE": "wholemodule",
        "SWIFT_OPTIMIZATION_LEVEL": "-O",
    })
    configs_section.add(config(test_debug, "Debug", test_debug_settings))
    configs_section.add(config(test_release, "Release", test_release_settings))

    def config_list(cid: str, owner: str, debug_id: str, release_id: str) -> str:
        return (
            f"\t\t{cid} /* Build configuration list for {owner} */ = {{isa = XCConfigurationList; "
            f"buildConfigurations = (\n"
            f"\t\t\t\t{debug_id} /* Debug */,\n"
            f"\t\t\t\t{release_id} /* Release */,\n"
            f"\t\t\t); defaultConfigurationIsVisible = 0; defaultConfigurationName = Release; }};"
        )

    config_lists_section.add(config_list(project_config_list, "PBXProject \"DanceProgressionJournal\"", project_debug, project_release))
    config_lists_section.add(config_list(app_config_list, "PBXNativeTarget \"DanceProgressionJournal\"", app_debug, app_release))
    config_lists_section.add(config_list(test_config_list, "PBXNativeTarget \"DanceProgressionJournalTests\"", test_debug, test_release))

    # Project object.
    project_section = Section("PBXProject")
    project_section.add(
        f"\t\t{project_id} /* Project object */ = {{isa = PBXProject; attributes = {{"
        f"BuildIndependentTargetsInParallel = 1; LastSwiftUpdateCheck = 1600; "
        f"LastUpgradeCheck = 2610; TargetAttributes = {{"
        f"{app_target_id} = {{CreatedOnToolsVersion = 26.1; }}; "
        f"{test_target_id} = {{CreatedOnToolsVersion = 26.1; }}; }}; }}; "
        f"buildConfigurationList = {project_config_list} /* Build configuration list for PBXProject \"DanceProgressionJournal\" */; "
        f"compatibilityVersion = \"Xcode 14.0\"; developmentRegion = en; hasScannedForEncodings = 0; "
        f"knownRegions = (en, Base, ); mainGroup = {main_group_id}; "
        f"productRefGroup = {products_group_id} /* Products */; projectDirPath = \"\"; "
        f"projectRoot = \"\"; targets = (\n"
        f"\t\t\t\t{app_target_id} /* DanceProgressionJournal */,\n"
        f"\t\t\t\t{test_target_id} /* DanceProgressionJournalTests */,\n"
        f"\t\t\t); }};"
    )

    sections = [
        build_files,
        proxy_section,
        file_refs,
        frameworks_section,
        groups,
        targets_section,
        project_section,
        resources_section,
        sources_section,
        dependency_section,
        configs_section,
        config_lists_section,
    ]
    out = ["// !$*UTF8*$!", "{", "\tarchiveVersion = 1;", "\tclasses = {", "\t};", "\tobjectVersion = 60;", "\tobjects = {"]
    for section in sections:
        out.append(f"\n/* Begin {section.name} section */")
        out.extend(section.entries)
        out.append(f"/* End {section.name} section */")
    out.append("\t};")
    out.append(f"\trootObject = {project_id} /* Project object */;")
    out.append("}")

    OUT.mkdir(parents=True, exist_ok=True)
    (OUT / "project.pbxproj").write_text("\n".join(out) + "\n", encoding="utf-8")

    workspace = OUT / "project.xcworkspace"
    workspace.mkdir(parents=True, exist_ok=True)
    (workspace / "contents.xcworkspacedata").write_text(
        '<?xml version="1.0" encoding="UTF-8"?>\n'
        "<Workspace\n"
        '   version = "1.0">\n'
        "   <FileRef\n"
        '      location = "self:">\n'
        "   </FileRef>\n"
        "</Workspace>\n",
        encoding="utf-8",
    )
    print(f"Wrote {OUT / 'project.pbxproj'}")
    print(f"App sources: {len(app_swift)}, test sources: {len(test_swift)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
