# Lab 5 
This lab uses http server as well as machine learning aspects.\
Video link: https://www.dropbox.com/sh/evo6y8yigxzrvk4/AADC4z7Isd41BzQdPWV7HSeXa?dl=0
## Some instructions
- Add image
  - Images are taken from the camera. Editing is allowed for cropping and zooming in the pictures taken.
  - Does sanity check to check if corresponding label is selected or if the picture is taken
  - Converts to pixel data and send them to the server
- Train
  - Training requires each label has at least on image.
- Train and Compare Models
  - Training and comparing models requires at least 4 images for each label.
  - Models: Logistic regression and boosted decision tree
- Prediction
  - Default is the logistic regression from the server. If the model is not available, an alert will show up.
  - Models: Logistic regression and boosted decision tree. Pre-trained Logistic regression and boosted decision tree.
  - Requires an image to be taken from the camera
