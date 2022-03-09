# -*- coding: utf-8 -*-
"""
@author: Quentin
K-means sur des images
"""

#%% Imports

import cv2
import numpy as np
import matplotlib.pyplot as plt
import time
import random

#%% Génération de l'image segmentée

start = time.time()
image_toRead_path = r'C:\Users\Quentin\Desktop\Le Reste\ProjetENSTAHusky\carteTemperature.png'
image_toSave_path = r'C:\Users\Quentin\Desktop\Le Reste\ProjetENSTAHusky\carteTemperatureTraitee.png'

# lit l'image et la convertie en rgb
image = cv2.imread(image_toRead_path)
image = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)

# change l'image de (largeur, longueur, rgb) à un seul vecteur de pixels
pixel_values = np.float32(image.reshape((-1, 3)))

# définition du critère d'arrêt (nb essais, epsilon)
criteria = (cv2.TERM_CRITERIA_EPS + cv2.TERM_CRITERIA_MAX_ITER, 100, 0.2)   
k = 5
_, labels, (centers) = cv2.kmeans(pixel_values, k, None, criteria, 10, cv2.KMEANS_RANDOM_CENTERS)

# conversion des floats récupérés en uint8
centers = np.uint8(centers)
labels = labels.flatten()

# reconstruction de l'image
segmented_image = centers[labels.flatten()]
segmented_image = segmented_image.reshape(image.shape)

end = time.time()

print("Temps d'exécution : {} secs".format(end - start))

cv2.imwrite(image_toSave_path, segmented_image)
plt.imshow(segmented_image)
plt.show()

#%% génération de distances

values = []
distance_values = []
distance_path = r'C:\Users\Quentin\Desktop\Le Reste\ProjetENSTAHusky\carteDistance.txt'

for i in range(k):
    random_value = random.randrange(0 + 200*i, 200 + 200*i, 50)
    values.append(random_value)

for i in range(len(labels)):
    epsilon = random.randrange(-25, 25, 1)
    distance_values.append(values[labels[i]] + epsilon)

distance_file = open(distance_path, "a")
for i in range(len(distance_values)):
    if(i//len(image) != 0 and i%len(image) == 0):
        distance_file.write('\n')
    distance_file.write(str(distance_values[i]))
    distance_file.write(" ")
distance_file.close()

checksum = 0
for i in range(len(distance_values)):
    checksum += distance_values[i]
print(checksum)























