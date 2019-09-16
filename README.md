# Continuous wavelet filtering on webcam photoplethysmographic signals to remotely assess the instantaneous heart rate

Remote pulse rate measurement from facial video has gained particular attention over the last few years. Researches exhibit significant advancements and demonstrate that common video cameras correspond to reliable devices that can be employed to measure a large set of biomedical parameters without any contact with the subject.

This repository contains the source codes related to a method that combines skin detection, colorspace conversion and analysis of the iPPG signal using its time-frequency representation (continuous wavelet transform).


## Reference
If you find this code useful or use it in an academic or research project, please cite it as: 

Frédéric Bousefsaf, Alain Pruski, Choubeila Maaoui, **Continuous wavelet filtering on webcam photoplethysmographic signals to remotely assess the instantaneous heart rate**, *Biomedical Signal Processing and Control*, vol. 8, n° 6, pp. 568–574 (2013).


## Scientific description
Please refer to the original publication to get all the details. Three main contributions were proposed:
- A skin detection that allows selection of pixels of interests.
- A change in colorspace (CIE Luv) to improve robustness over lighting fluctuations.
- A filtering procedure based on the continuous wavelet representation of the iPPG signal.

![Alt text](illustrations/method.png?raw=true "Method")

*Processing algorithm overview. (a) Face tracking. (b) Pixels that contain PPG information are isolated by skin detection. (c) The RGB colorspace is converted to the CIE Luv. (d) The u frame is combined with the skin detection frame by a combinational AND operation. (e) A spatial averaging step is performed to transform a set of frames into a single raw signal.*

The raw signal is then processed using continuous wavelet transform. The time-frequency representation is filtered according to the total energy distribution:

![Alt text](illustrations/cwt.png?raw=true "iPPG signal processing using cwt")

*(a) The energy curve is used to filter the CWT spectrogram, presented in (b). (c) The reconstruction gives a detrended and denoised version of the raw signal. Left figure: processing of a typical raw PPG signal, right figure: processing of a typical pulse rate signal to compute breathing rate (respiratory sinus arrhythmia).*

## Requirements
The codes were developped and tested in Matlab R2018b. The Computer Vision System Toolbox is required for face detection and tracking.


## Usage
Function inputs: 
- `file`: source folder path (.png images) or video path/filename.
- `mode`: 'video' or 'folder'. If 'folder' is specified, images must follow a %04d template that starts from 0, i.e. '0000.png', '0001.png'...
- `display`: 0 = no display, 1 = display signals only, 2 = display signals and face tracking.


Function outputs: 
- `iPPG_time30`, `iPPG_signal30filt`: iPPG signal and time vectors (u* channel filtered using its CWT representation).
- `iPR_time`, `iPR`: instantaneous (beat-to-beat) pulse rate.
- `iBR_time`, `iBR`: instantaneous (beat-to-beat) breathing rate.

Below is a typical usage example. A test sample is available  [here](https://drive.google.com/open?id=17l_MJVqw4F9cQpcJ-_wFmFNr3bdZNtw9) (sample_front.zip). The folder contains the time vector along with uncompressed images. 

`ippg_luv_skindetect_cwt('C:\sample_front', 'folder', 1);`
