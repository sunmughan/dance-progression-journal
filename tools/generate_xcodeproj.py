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
ADMIN_DIR = REPO / "DanceProgressionJournalAdmin"
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
    admin_swift = sorted(ADMIN_DIR.rglob("*.swift"))
    test_swift = sorted(TEST_DIR.rglob("*.swift"))
    info_plist = APP_DIR / "Info.plist"
    admin_plist = ADMIN_DIR / "Info.plist"
    assets = APP_DIR / "Assets.xcassets"

    build_files = Section("PBXBuildFile")
    file_refs = Section("PBXFileReference")
    groups = Section("PBXGroup")
    sources_app: list[str] = []
    sources_admin: list[str] = []
    sources_test: list[str] = []
    resources_app: list[str] = []
    resources_admin: list[str] = []

    # Build file id per repo relative path, so the admin target reuses
    # the same PBXBuildFile objects for the shared sources.
    build_file_by_rel: dict[str, str] = {}

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
        build_file_by_rel[path.relative_to(REPO).as_posix()] = bf
        build_files.add(
            f"\t\t{bf} /* {path.name} in Sources */ = {{isa = PBXBuildFile; fileRef = {fid} /* {path.name} */; }};"
        )
        sources_app.append(bf)
        # The admin target compiles every app source except the user
        # app entry point, which carries the user @main. The admin
        # @main lives in the admin directory.
        if path.name != "DanceProgressionJournalApp.swift":
            sources_admin.append(bf)
        app_file_ids.setdefault(parent, []).append(fid)

    # Admin source files, grouped by parent folder relative to
    # ADMIN_DIR. These compile into the admin target only.
    admin_file_ids: dict[str, list[str]] = {}
    for path in admin_swift:
        rel = path.relative_to(ADMIN_DIR)
        parent = str(rel.parent) if str(rel.parent) != "." else ""
        fid, entry = file_ref(path, "swift")
        file_refs.add(entry)
        bf = pbx_id("buildfile:" + path.relative_to(REPO).as_posix())
        build_file_by_rel[path.relative_to(REPO).as_posix()] = bf
        build_files.add(
            f"\t\t{bf} /* {path.name} in Sources */ = {{isa = PBXBuildFile; fileRef = {fid} /* {path.name} */; }};"
        )
        sources_admin.append(bf)
        admin_file_ids.setdefault(parent, []).append(fid)

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
    admin_plist_id, admin_plist_entry = file_ref(admin_plist, "plist")
    file_refs.add(admin_plist_entry)
    assets_id, assets_entry = file_ref(assets, "xcassets")
    file_refs.add(assets_entry)
    assets_bf = pbx_id("buildfile:Assets.xcassets")
    build_files.add(
        f"\t\t{assets_bf} /* Assets.xcassets in Resources */ = {{isa = PBXBuildFile; fileRef = {assets_id} /* Assets.xcassets */; }};"
    )
    resources_app.append(assets_bf)
    # The admin app reuses the same asset catalog for its icon and
    # accent colour until it gets its own.
    resources_admin.append(assets_bf)

    # Product references.
    app_product_id, app_product_entry = file_ref(
        REPO / "DanceProgressionJournal.app", "app"
    )
    admin_product_id, admin_product_entry = file_ref(
        REPO / "DanceProgressionJournalAdmin.app", "app"
    )
    test_product_id, test_product_entry = file_ref(
        REPO / "DanceProgressionJournalTests.xctest", "xctest"
    )
    # Products live in the Products group, path is just the file name.
    app_product_entry = app_product_entry.replace(
        f"path = {q('DanceProgressionJournal.app')}",
        "path = DanceProgressionJournal.app",
    )
    admin_product_entry = admin_product_entry.replace(
        f"path = {q('DanceProgressionJournalAdmin.app')}",
        "path = DanceProgressionJournalAdmin.app",
    )
    test_product_entry = test_product_entry.replace(
        f"path = {q('DanceProgressionJournalTests.xctest')}",
        "path = DanceProgressionJournalTests.xctest",
    )
    file_refs.add(app_product_entry)
    file_refs.add(admin_product_entry)
    file_refs.add(test_product_entry)

    # Groups.
    main_group_id = group_id("main")
    app_group_id = group_id("DanceProgressionJournal")
    admin_group_id = group_id("DanceProgressionJournalAdmin")
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

    # Admin subgroups and admin group, mirroring the app group.
    admin_subgroup_ids: dict[str, str] = {}
    for parent in sorted(admin_file_ids):
        if parent == "":
            continue
        gid = group_id("admin:" + parent)
        admin_subgroup_ids[parent] = gid
        children = "".join(
            f"\t\t\t\t{pbx_id('fileref:' + p.relative_to(REPO).as_posix())} /* {p.name} */,\n"
            for p in admin_swift
            if str(p.relative_to(ADMIN_DIR).parent) == parent
        )
        groups.add(
            f"\t\t{gid} /* {parent.split('/')[-1]} */ = {{isa = PBXGroup; children = (\n"
            f"{children}\t\t\t); name = {q(parent.split('/')[-1])}; path = {q(parent)}; sourceTree = \"<group>\"; }};"
        )
    admin_root_children = "".join(
        f"\t\t\t\t{pbx_id('fileref:' + p.relative_to(REPO).as_posix())} /* {p.name} */,\n"
        for p in admin_swift
        if str(p.relative_to(ADMIN_DIR).parent) == "."
    )
    admin_subgroup_children_text = "".join(
        f"\t\t\t\t{admin_subgroup_ids[p]} /* {p.split('/')[-1]} */,\n"
        for p in sorted(admin_subgroup_ids)
    )
    groups.add(
        f"\t\t{admin_group_id} /* DanceProgressionJournalAdmin */ = {{isa = PBXGroup; children = (\n"
        f"{admin_root_children}{admin_subgroup_children_text}"
        f"\t\t\t\t{admin_plist_id} /* Info.plist */,\n"
        f"\t\t\t); path = DanceProgressionJournalAdmin; sourceTree = \"<group>\"; }};"
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
        f"\t\t\t\t{admin_product_id} /* DanceProgressionJournalAdmin.app */,\n"
        f"\t\t\t\t{test_product_id} /* DanceProgressionJournalTests.xctest */,\n"
        f"\t\t\t); name = Products; sourceTree = \"<group>\"; }};"
    )
    groups.add(
        f"\t\t{main_group_id} = {{isa = PBXGroup; children = (\n"
        f"\t\t\t\t{app_group_id} /* DanceProgressionJournal */,\n"
        f"\t\t\t\t{admin_group_id} /* DanceProgressionJournalAdmin */,\n"
        f"\t\t\t\t{test_group_id} /* DanceProgressionJournalTests */,\n"
        f"\t\t\t\t{products_group_id} /* Products */,\n"
        f"\t\t\t); sourceTree = \"<group>\"; }};"
    )

    # Firebase Swift Package Manager products. Both the user app and
    # the admin app link the same five products. Firebase 13, SPM
    # only, minimum 13.0.0. The SDK is configured only when a real
    # GoogleService-Info.plist is present in the bundle; without it
    # FirebaseService stays a no op and the apps work fully offline.
    firebase_products = [
        "FirebaseAnalytics",
        "FirebaseCrashlytics",
        "FirebaseAuth",
        "FirebaseFirestore",
        "FirebaseStorage",
    ]
    package_id = pbx_id("package:firebase")
    package_section = Section("XCRemoteSwiftPackageReference")
    package_section.add(
        f"\t\t{package_id} /* XCRemoteSwiftPackageReference \"firebase-ios-sdk\" */ = {{isa = XCRemoteSwiftPackageReference; "
        f"repositoryURL = \"https://github.com/firebase/firebase-ios-sdk\"; "
        f"requirement = {{kind = upToNextMajorVersion; minimumVersion = 13.0.0; }}; }};"
    )
    product_dep_section = Section("XCSwiftPackageProductDependency")
    product_dep_ids: dict[str, str] = {}
    for product in firebase_products:
        dep_id = pbx_id("productdep:" + product)
        product_dep_ids[product] = dep_id
        product_dep_section.add(
            f"\t\t{dep_id} /* {product} */ = {{isa = XCSwiftPackageProductDependency; "
            f"package = {package_id} /* XCRemoteSwiftPackageReference \"firebase-ios-sdk\" */; productName = {product}; }};"
        )
        bf = pbx_id("buildfile:firebase:" + product)
        build_files.add(
            f"\t\t{bf} /* {product} in Frameworks */ = {{isa = PBXBuildFile; productRef = {dep_id} /* {product} */; }};"
        )
    firebase_frameworks_app = [
        pbx_id("buildfile:firebase:" + product) for product in firebase_products
    ]
    firebase_frameworks_admin = list(firebase_frameworks_app)

    # Build phases.
    sources_app_id = pbx_id("phase:sources:app")
    sources_admin_id = pbx_id("phase:sources:admin")
    sources_test_id = pbx_id("phase:sources:test")
    resources_app_id = pbx_id("phase:resources:app")
    resources_admin_id = pbx_id("phase:resources:admin")
    frameworks_app_id = pbx_id("phase:frameworks:app")
    frameworks_admin_id = pbx_id("phase:frameworks:admin")
    frameworks_test_id = pbx_id("phase:frameworks:test")

    def phase_list(phase_id: str, kind: str, name: str, files: list[str], target_comment: str) -> str:
        files_text = "".join(f"\t\t\t\t{f} /* {name} */,\n" for f in files)
        return (
            f"\t\t{phase_id} /* {name} */ = {{isa = {kind}; buildActionMask = 2147483647; "
            f"files = (\n{files_text}\t\t\t); runOnlyForDeploymentPostprocessing = 0; }};"
        )

    sources_section = Section("PBXSourcesBuildPhase")
    sources_section.add(phase_list(sources_app_id, "PBXSourcesBuildPhase", "Sources", sources_app, "app"))
    sources_section.add(phase_list(sources_admin_id, "PBXSourcesBuildPhase", "Sources", sources_admin, "admin"))
    sources_section.add(phase_list(sources_test_id, "PBXSourcesBuildPhase", "Sources", sources_test, "test"))
    resources_section = Section("PBXResourcesBuildPhase")
    resources_section.add(phase_list(resources_app_id, "PBXResourcesBuildPhase", "Resources", resources_app, "app"))
    resources_section.add(phase_list(resources_admin_id, "PBXResourcesBuildPhase", "Resources", resources_admin, "admin"))
    frameworks_section = Section("PBXFrameworksBuildPhase")
    frameworks_app_files = "".join(
        f"\t\t\t\t{bf} /* {product} in Frameworks */,\n"
        for bf, product in zip(firebase_frameworks_app, firebase_products)
    )
    frameworks_admin_files = "".join(
        f"\t\t\t\t{bf} /* {product} in Frameworks */,\n"
        for bf, product in zip(firebase_frameworks_admin, firebase_products)
    )
    frameworks_section.add(
        f"\t\t{frameworks_app_id} /* Frameworks */ = {{isa = PBXFrameworksBuildPhase; buildActionMask = 2147483647; files = (\n"
        f"{frameworks_app_files}\t\t\t); runOnlyForDeploymentPostprocessing = 0; }};"
    )
    frameworks_section.add(
        f"\t\t{frameworks_admin_id} /* Frameworks */ = {{isa = PBXFrameworksBuildPhase; buildActionMask = 2147483647; files = (\n"
        f"{frameworks_admin_files}\t\t\t); runOnlyForDeploymentPostprocessing = 0; }};"
    )
    frameworks_section.add(
        f"\t\t{frameworks_test_id} /* Frameworks */ = {{isa = PBXFrameworksBuildPhase; buildActionMask = 2147483647; files = (); runOnlyForDeploymentPostprocessing = 0; }};"
    )

    # Targets.
    app_target_id = pbx_id("target:app")
    admin_target_id = pbx_id("target:admin")
    test_target_id = pbx_id("target:test")
    app_config_list = pbx_id("configlist:app")
    admin_config_list = pbx_id("configlist:admin")
    test_config_list = pbx_id("configlist:test")
    project_config_list = pbx_id("configlist:project")
    project_id = pbx_id("project")
    proxy_id = pbx_id("proxy:testdep")
    dependency_id = pbx_id("dependency:testdep")

    targets_section = Section("PBXNativeTarget")
    package_deps_text = "".join(
        f"\t\t\t\t{product_dep_ids[product]} /* {product} */,\n"
        for product in firebase_products
    )
    targets_section.add(
        f"\t\t{app_target_id} /* DanceProgressionJournal */ = {{isa = PBXNativeTarget; "
        f"buildConfigurationList = {app_config_list} /* Build configuration list for PBXNativeTarget \"DanceProgressionJournal\" */; "
        f"buildPhases = (\n"
        f"\t\t\t\t{sources_app_id} /* Sources */,\n"
        f"\t\t\t\t{frameworks_app_id} /* Frameworks */,\n"
        f"\t\t\t\t{resources_app_id} /* Resources */,\n"
        f"\t\t\t); buildRules = (); dependencies = (); name = DanceProgressionJournal; "
        f"packageProductDependencies = (\n{package_deps_text}\t\t\t); "
        f"productName = DanceProgressionJournal; productReference = {app_product_id} /* DanceProgressionJournal.app */; "
        f"productType = \"com.apple.product-type.application\"; }};"
    )
    targets_section.add(
        f"\t\t{admin_target_id} /* DanceProgressionJournalAdmin */ = {{isa = PBXNativeTarget; "
        f"buildConfigurationList = {admin_config_list} /* Build configuration list for PBXNativeTarget \"DanceProgressionJournalAdmin\" */; "
        f"buildPhases = (\n"
        f"\t\t\t\t{sources_admin_id} /* Sources */,\n"
        f"\t\t\t\t{frameworks_admin_id} /* Frameworks */,\n"
        f"\t\t\t\t{resources_admin_id} /* Resources */,\n"
        f"\t\t\t); buildRules = (); dependencies = (); name = DanceProgressionJournalAdmin; "
        f"packageProductDependencies = (\n{package_deps_text}\t\t\t); "
        f"productName = DanceProgressionJournalAdmin; productReference = {admin_product_id} /* DanceProgressionJournalAdmin.app */; "
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
    admin_debug = pbx_id("config:admin:debug")
    admin_release = pbx_id("config:admin:release")
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

    admin_common = dict(app_common)
    admin_common.update({
        "INFOPLIST_FILE": "DanceProgressionJournalAdmin/Info.plist",
        "PRODUCT_BUNDLE_IDENTIFIER": "com.codeair.danceprogressionjournal.admin",
    })
    admin_debug_settings = dict(admin_common)
    admin_debug_settings.update({
        "DEBUG_INFORMATION_FORMAT": "dwarf",
        "ENABLE_TESTABILITY": "YES",
        "SWIFT_ACTIVE_COMPILATION_CONDITIONS": "DEBUG",
        "SWIFT_OPTIMIZATION_LEVEL": "-Onone",
    })
    admin_release_settings = dict(admin_common)
    admin_release_settings.update({
        "DEBUG_INFORMATION_FORMAT": "dwarf-with-dsym",
        "SWIFT_COMPILATION_MODE": "wholemodule",
        "SWIFT_OPTIMIZATION_LEVEL": "-O",
        "SWIFT_TREAT_WARNINGS_AS_ERRORS": "YES",
    })
    configs_section.add(config(admin_debug, "Debug", admin_debug_settings))
    configs_section.add(config(admin_release, "Release", admin_release_settings))

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
    config_lists_section.add(config_list(admin_config_list, "PBXNativeTarget \"DanceProgressionJournalAdmin\"", admin_debug, admin_release))
    config_lists_section.add(config_list(test_config_list, "PBXNativeTarget \"DanceProgressionJournalTests\"", test_debug, test_release))

    # Project object.
    project_section = Section("PBXProject")
    project_section.add(
        f"\t\t{project_id} /* Project object */ = {{isa = PBXProject; attributes = {{"
        f"BuildIndependentTargetsInParallel = 1; LastSwiftUpdateCheck = 1600; "
        f"LastUpgradeCheck = 2610; TargetAttributes = {{"
        f"{app_target_id} = {{CreatedOnToolsVersion = 26.1; }}; "
        f"{admin_target_id} = {{CreatedOnToolsVersion = 26.1; }}; "
        f"{test_target_id} = {{CreatedOnToolsVersion = 26.1; }}; }}; }}; "
        f"buildConfigurationList = {project_config_list} /* Build configuration list for PBXProject \"DanceProgressionJournal\" */; "
        f"compatibilityVersion = \"Xcode 14.0\"; developmentRegion = en; hasScannedForEncodings = 0; "
        f"knownRegions = (en, Base, ); mainGroup = {main_group_id}; "
        f"packageReferences = (\n"
        f"\t\t\t\t{package_id} /* XCRemoteSwiftPackageReference \"firebase-ios-sdk\" */,\n"
        f"\t\t\t); "
        f"productRefGroup = {products_group_id} /* Products */; projectDirPath = \"\"; "
        f"projectRoot = \"\"; targets = (\n"
        f"\t\t\t\t{app_target_id} /* DanceProgressionJournal */,\n"
        f"\t\t\t\t{admin_target_id} /* DanceProgressionJournalAdmin */,\n"
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
        package_section,
        product_dep_section,
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
    print(f"App sources: {len(app_swift)}, admin sources: {len(admin_swift)}, test sources: {len(test_swift)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
