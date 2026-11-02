# Sumber dan atribusi

- RTMPose / MMPose: OpenMMLab, arXiv:2303.07399. Kode proyek MMPose berlisensi Apache-2.0; salinannya ada di LICENSES/MMPose-Apache-2.0.txt. Model AP10K diterima langsung dari arsip resmi OpenMMLab, checksum tercatat di Resources/model-manifest.json. Sumber: https://github.com/open-mmlab/mmpose/tree/main/projects/rtmpose
- AP-10K: Yu et al., “AP-10K: A Benchmark for Animal Pose Estimation in the Wild”, NeurIPS Datasets and Benchmarks 2021. Repository menyatakan dataset CC-BY-4.0: https://github.com/AlexTheBad/AP-10K . Tidak ada dataset atau foto AP10K yang didistribusikan dalam paket ini. Model ini merupakan baseline quadruped, bukan model landmark metrologi sapi.
- ONNX Runtime: Microsoft, MIT. LICENSES/ONNXRuntime-MIT.txt. Swift package resmi dipin ke 1.20.0: https://github.com/microsoft/onnxruntime-swift-package-manager/tree/1.20.0 . Framework diunduh Swift Package Manager pada setup.
- Apple ARKit scene depth: https://developer.apple.com/documentation/arkit/displaying-a-point-cloud-using-scene-depth
- Apple Vision Human: https://developer.apple.com/documentation/vision/detecting-human-body-poses-in-images
- Apple Vision Animal: https://developer.apple.com/videos/play/wwdc2023/10045/
- Peng et al., Animals 2024: https://doi.org/10.3390/ani14172453 . Menginspirasi pendekatan satu sisi; estimator ellipse v0 dalam aplikasi ini bukan replikasi algoritme paper tersebut.

Atribusi ini membedakan lisensi kode, dataset, dan checkpoint. Sebelum distribusi komersial, tinjau terms checkpoint dan seluruh sumber pretraining AIC/COCO dari penerbit; paket ini disiapkan untuk pengembangan internal. Tidak ada model SuperAnimal berlisensi nonkomersial yang dibundel.
