# Zoo Prague iOS application
An iOS application for visitors of Zoo Prague which is part of my Master's thesis. It uses data collected by the [created server](https://github.com/budikpet/MastersThesis_Server).

Launch screen             |  Lexicon view | Lexicon view - search bar
:-------------------------:|:-------------------------:|:-------------------------:
![alt text][launchScreen]       |  ![alt text][lexiconView] | ![alt text][lexiconView_Search]

Animal detail view 1             |  Animal detail view 2
:-------------------------:|:-------------------------:
![alt text][animalDetailView_1] | ![alt text][animalDetailView_2] 

Map view             |
:-------------------------:|
![alt text][mapView] |

Map view - highlighted animal pen | Map view - navigation
:-------------------------:|:-------------------------:
![alt text][mapView_Highlighted] | ![alt text][mapView_Navigation]

[launchScreen]: DocumentationImages/LaunchScreen.png?raw=true "Launch screen"
[lexiconView]: DocumentationImages/LexiconView.png?raw=true "Launch screen"
[lexiconView_Search]: DocumentationImages/LexiconView_Search.png?raw=true "Launch screen"
[animalDetailView_1]: DocumentationImages/AnimalDetailView_1.png?raw=true "Launch screen"
[animalDetailView_2]: DocumentationImages/AnimalDetailView_2.png?raw=true "Launch screen"
[mapView]: DocumentationImages/MapView.png?raw=true "Launch screen"
[mapView_Highlighted]: DocumentationImages/MapView_Highlighted.png?raw=true "Launch screen"
[mapView_Navigation]: DocumentationImages/MapView_Navigation.png?raw=true "Launch screen"

## Features
- Zoo Prague lexicon which contains information about all animals here
    - can be filtered;
    - can be used to find a place where the animal is.
- A map of Zoo Prague which is integrated with the lexicon
    - fully offline and constrained to Zoo Prague and surrounding area;
    - shows locations of animals;
    - makes it possible to navigate to a point on the map or a specific location.

## How to build manually
API keys for automated localization through ACKLocalization need to be provided. Use [official documentation](https://github.com/AckeeCZ/ACKLocalization#use-with-service-account) to prepare the library itself and a [step-by-step](https://cloud.google.com/iam/docs/creating-managing-service-account-keys) guide for creating Google development console Service account key. It mainly requires the service account specified through the file *Localization/localizationServiceAccount.json.fill* that is downloaded from the Google development console.
