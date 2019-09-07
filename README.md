# Continuous wavelet filtering on webcam photoplethysmographic signals to remotely assess the instantaneous heart rate

Remote pulse rate measurement from facial video has gained particular attention over the last few years. Researches exhibit significant advancements and demonstrate that common video cameras correspond to reliable devices that can be employed to measure a large set of biomedical parameters without any contact with the subject.

This repository contains the source codes related to a method that combines skin detection, colorspace conversion and analysis of the iPPG signal using its time-frequency representation (continuous wavelet transform).


## Reference
If you find this code useful or use it in an academic or research project, please cite it as: 

Frédéric Bousefsaf, Alain Pruski, Choubeila Maaoui, **Continuous wavelet filtering on webcam photoplethysmographic signals to remotely assess the instantaneous heart rate**, *Biomedical Signal Processing and Control*, vol. 8, n° 6, pp. 568–574 (2013).


## Scientific description
Please refer to the original publication to get all the details. Three main contributions were proposed:
- A skin detection that allows selection of pixels of interests.
- A change in colorspace (CIE Luv) to improve robustness over lightning fluctuations.
- A filtering procedure based on the continuous wavelet representation of the iPPG signal.

![Alt text](illustrations/method.png?raw=true "Method")

*Processing algorithm overview. (a) Face tracking. (b) Pixels that contain PPG information are isolated by skin detection. (c) The RGB colorspace is converted to the CIE Luv. (d) The u frame is combined with the skin detection frame by a combinational AND operation. (e) A spatial averaging step is performed to transform a set of frames into a single raw signal.*


## Requirements
The codes were developped and tested in Matlab.


## Usage
This repository contains
