"""Regenerate deterministic Xcode project. Python standard library only."""
from pathlib import Path
import hashlib,plistlib
root=Path(__file__).resolve().parents[1]
def ident(s):return hashlib.sha1(s.encode()).hexdigest()[:24].upper()
def q(s):return '"'+s.replace('"','\\"')+'"'
objects=[]
def obj(name,body):objects.append(f'{ident(name)} = {{ {body} }};');return ident(name)
source_files=sorted(root.glob('App/*.swift'))+sorted(root.glob('Core/*.swift'))
resources=[root/'Resources/AnimalPose.onnx']
builds=[];resource_builds=[];groups={}
for p in source_files+resources:
 rel=p.relative_to(root).as_posix();ft='sourcecode.swift' if p.suffix=='.swift' else 'file'
 ref=obj(rel,f'isa = PBXFileReference; lastKnownFileType = {ft}; path = {q(rel)}; sourceTree = "<group>";')
 b=obj(rel+'-build',f'isa = PBXBuildFile; fileRef = {ref};')
 (builds if p in source_files else resource_builds).append(b)
 groups.setdefault(p.parent.name,[]).append(ref)
product=obj('product','isa = PBXFileReference; explicitFileType = wrapper.application; path = SapiMeasure.app; sourceTree = BUILT_PRODUCTS_DIR;')
products=obj('products',f'isa = PBXGroup; children = ({product},); name = Products; sourceTree = "<group>";')
groupids=[]
for name,refs in groups.items():groupids.append(obj('group-'+name,f'isa = PBXGroup; children = ({",".join(refs)},); name = {name}; sourceTree = "<group>";'))
rootgroup=obj('root',f'isa = PBXGroup; children = ({",".join(groupids+[products])},); sourceTree = "<group>";')
sources=obj('sources',f'isa = PBXSourcesBuildPhase; buildActionMask = 2147483647; files = ({",".join(builds)},); runOnlyForDeploymentPostprocessing = 0;')
resourcephase=obj('resources',f'isa = PBXResourcesBuildPhase; buildActionMask = 2147483647; files = ({",".join(resource_builds)},); runOnlyForDeploymentPostprocessing = 0;')
package=obj('ort-package','isa = XCRemoteSwiftPackageReference; repositoryURL = "https://github.com/microsoft/onnxruntime-swift-package-manager"; requirement = {kind = exactVersion; version = 1.20.0;};')
packageproduct=obj('ort-product',f'isa = XCSwiftPackageProductDependency; package = {package}; productName = onnxruntime;')
frameworkbuild=obj('ort-build',f'isa = PBXBuildFile; productRef = {packageproduct};')
frameworks=obj('frameworks',f'isa = PBXFrameworksBuildPhase; buildActionMask = 2147483647; files = ({frameworkbuild},); runOnlyForDeploymentPostprocessing = 0;')
projconfigs=[];targetconfigs=[]
for name in ['Debug','Release']:
 projconfigs.append(obj('project-'+name,f'isa = XCBuildConfiguration; name = {name}; buildSettings = {{ CLANG_ENABLE_MODULES = YES; SDKROOT = iphoneos; IPHONEOS_DEPLOYMENT_TARGET = 17.0; SWIFT_VERSION = 5.0; }};'))
 targetconfigs.append(obj('target-'+name,f'''isa = XCBuildConfiguration; name = {name}; buildSettings = {{
 PRODUCT_NAME = "$(TARGET_NAME)"; PRODUCT_BUNDLE_IDENTIFIER = dev.salman.SapiMeasure;
 INFOPLIST_FILE = App/Info.plist; GENERATE_INFOPLIST_FILE = NO;
 CODE_SIGN_STYLE = Automatic; DEVELOPMENT_TEAM = ""; TARGETED_DEVICE_FAMILY = 1;
 SWIFT_VERSION = 5.0; SWIFT_OPTIMIZATION_LEVEL = "{'-Onone' if name=='Debug' else '-O'}";
 SWIFT_ACTIVE_COMPILATION_CONDITIONS = "{'DEBUG' if name=='Debug' else ''}";
 IPHONEOS_DEPLOYMENT_TARGET = 17.0; SUPPORTED_PLATFORMS = "iphoneos iphonesimulator";
 LD_RUNPATH_SEARCH_PATHS = ("$(inherited)","@executable_path/Frameworks");
 CURRENT_PROJECT_VERSION = 1; MARKETING_VERSION = 0.1.0; ENABLE_PREVIEWS = YES;
 }};'''))
pc=obj('project-configs',f'isa = XCConfigurationList; buildConfigurations = ({",".join(projconfigs)},); defaultConfigurationIsVisible = 0; defaultConfigurationName = Release;')
tc=obj('target-configs',f'isa = XCConfigurationList; buildConfigurations = ({",".join(targetconfigs)},); defaultConfigurationIsVisible = 0; defaultConfigurationName = Release;')
target=obj('target',f'isa = PBXNativeTarget; buildConfigurationList = {tc}; buildPhases = ({sources},{frameworks},{resourcephase},); buildRules = (); dependencies = (); name = SapiMeasure; packageProductDependencies = ({packageproduct},); productName = SapiMeasure; productReference = {product}; productType = "com.apple.product-type.application";')
project=obj('project',f'isa = PBXProject; attributes = {{LastUpgradeCheck = 1600;}}; buildConfigurationList = {pc}; compatibilityVersion = "Xcode 14.0"; developmentRegion = en; hasScannedForEncodings = 0; knownRegions = (en,Base,id); mainGroup = {rootgroup}; productRefGroup = {products}; projectDirPath = ""; projectRoot = ""; packageReferences = ({package},); targets = ({target},);')
p=root/'SapiMeasure.xcodeproj';p.mkdir(exist_ok=True)
(p/'project.pbxproj').write_text('// !$*UTF8*$!\n{ archiveVersion = 1; classes = {}; objectVersion = 56; objects = {\n'+'\n'.join(objects)+'\n}; rootObject = '+project+'; }\n')
scheme=p/'xcshareddata/xcschemes';scheme.mkdir(parents=True,exist_ok=True)
ref=f'<BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{target}" BuildableName="SapiMeasure.app" BlueprintName="SapiMeasure" ReferencedContainer="container:SapiMeasure.xcodeproj"/>'
(scheme/'SapiMeasure.xcscheme').write_text(f'''<?xml version="1.0" encoding="UTF-8"?>
<Scheme LastUpgradeVersion="1600" version="1.3">
<BuildAction parallelizeBuildables="YES" buildImplicitDependencies="YES"><BuildActionEntries><BuildActionEntry buildForTesting="YES" buildForRunning="YES" buildForProfiling="YES" buildForArchiving="YES" buildForAnalyzing="YES">{ref}</BuildActionEntry></BuildActionEntries></BuildAction>
<TestAction buildConfiguration="Debug"/>
<LaunchAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB" launchStyle="0" useCustomWorkingDirectory="NO" ignoresPersistentStateOnLaunch="NO" debugDocumentVersioning="YES" debugServiceExtension="internal" allowLocationSimulation="YES"><BuildableProductRunnable runnableDebuggingMode="0">{ref}</BuildableProductRunnable></LaunchAction>
<ProfileAction buildConfiguration="Release"><BuildableProductRunnable runnableDebuggingMode="0">{ref}</BuildableProductRunnable></ProfileAction>
<AnalyzeAction buildConfiguration="Debug"/><ArchiveAction buildConfiguration="Release" revealArchiveInOrganizer="YES"/>
</Scheme>''')
info={'CFBundleDevelopmentRegion':'en','CFBundleExecutable':'$(EXECUTABLE_NAME)','CFBundleIdentifier':'$(PRODUCT_BUNDLE_IDENTIFIER)','CFBundleName':'SapiMeasure','CFBundleDisplayName':'SapiMeasure','CFBundlePackageType':'APPL','CFBundleShortVersionString':'$(MARKETING_VERSION)','CFBundleVersion':'$(CURRENT_PROJECT_VERSION)','LSRequiresIPhoneOS':True,'NSCameraUsageDescription':'Kamera dan LiDAR digunakan untuk foto serta estimasi ukuran tubuh. Data disimpan lokal.','UILaunchScreen':{},'UISupportedInterfaceOrientations':['UIInterfaceOrientationPortrait'],'UIApplicationSceneManifest':{'UIApplicationSupportsMultipleScenes':False}}
(root/'App/Info.plist').write_bytes(plistlib.dumps(info))
print('Generated',p)
