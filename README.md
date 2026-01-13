# DeGeMoH - Deep Generative Modelling on Hyperspheres
## Code to support the paper "Generative machine learning for multivariate angular simulation"

DeGeMoH - **De**ep **Ge**nerative **Mo**delling on **H**yperspheres

This repository contains Jupyter notebooks that can be used to fit all of the deep generative models considered in Wessel et al. (2025). A brief description of each script is given below. 

* **Tutorial Flow Matching.ipynb** - this file contains code for fitting the flow matching approach. View in browser [here](https://nbviewer.org/github/callumbarltrop/DeGeMoH/blob/main/Tutorial%20Flow%20Matching.ipynb).
* **Tutorial GAN.ipynb** - this file contains code for fitting the GAN approach. View in browser [here](https://nbviewer.org/github/callumbarltrop/DeGeMoH/blob/main/Tutorial%20GAN.ipynb).
* **Tutorial Normalizing Flows.ipynb** - this file contains code for fitting normalising flow approaches - specifically models based on neural spline flows and masked autoregressive flows. View in browser [here](https://nbviewer.org/github/callumbarltrop/DeGeMoH/blob/main/Tutorial%20Normalizing%20Flows.ipynb).

Alongside these notebooks, we also provide *R* code for fitting mixtures of von Mises-Fisher distributions, and for computing each of the goodness of fit metrics introduced in Section 3 of Wessel et al. (2025). These files are all contained in the **GOF** folder.

Due to large file sizes, we opted not to upload all of the visual diagnostics from Section 4 and 5 of Wessel et al. (2025) to this repository. These files have instead been stored on an online cloud server, and can be accessed via the link below. 

Link to datashare folder containing diagnostic files: https://datashare.tu-dresden.de/s/wNHmAfRJH25AwaX

## Questions?

Please get in touch if you have any questions, or if you find a bug in the code.  

### References

Wessel, J. B., Murphy-Barltrop, C. J., & Simpson, E. S. (2025). Generative machine learning for multivariate angular simulation. Extremes, 1-49.
