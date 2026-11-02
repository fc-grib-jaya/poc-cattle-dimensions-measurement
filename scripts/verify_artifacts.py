"""Portable checks. These DO NOT compile Swift or exercise ARKit on an iPhone.
Optional: pip install onnxruntime numpy tree-sitter tree-sitter-swift
"""
from pathlib import Path
import hashlib,json,plistlib,re,xml.etree.ElementTree as ET
root=Path(__file__).resolve().parents[1]
manifest=json.loads((root/'Resources/model-manifest.json').read_text())
model=root/'Resources/AnimalPose.onnx'
assert hashlib.sha256(model.read_bytes()).hexdigest()==manifest['sha256']
plistlib.loads((root/'App/Info.plist').read_bytes())
ET.parse(root/'SapiMeasure.xcodeproj/xcshareddata/xcschemes/SapiMeasure.xcscheme')
pbx=(root/'SapiMeasure.xcodeproj/project.pbxproj').read_text()
refs=set(re.findall(r'\b[A-F0-9]{24}\b',pbx));defs=re.findall(r'^([A-F0-9]{24}) =',pbx,re.M)
assert len(defs)==len(set(defs)) and refs==set(defs)
print('PASS: model checksum; project references; Info.plist; shared scheme')
try:
 from tree_sitter import Language,Parser
 import tree_sitter_swift
 parser=Parser(Language(tree_sitter_swift.language()))
 for file in root.rglob('*.swift'):
  if '.build' in file.parts:continue
  assert not parser.parse(file.read_bytes()).root_node.has_error,str(file)
 print('PASS: Swift syntax parser (not type checking)')
except ImportError:print('SKIP: install tree-sitter and tree-sitter-swift for syntax check')
try:
 import onnxruntime as ort,numpy as np
 session=ort.InferenceSession(str(model),providers=['CPUExecutionProvider'])
 inputs=session.get_inputs();assert len(inputs)==1 and inputs[0].shape[1:]==[3,256,256]
 outputs=session.run(['simcc_x','simcc_y'],{'input':np.zeros((1,3,256,256),dtype=np.float32)})
 assert all(o.shape==(1,17,512) and np.isfinite(o).all() for o in outputs)
 print('PASS: actual ONNX inference, finite [1,17,512] SimCC outputs; no accuracy claim')
except ImportError:print('SKIP: install onnxruntime and numpy for model smoke test')
