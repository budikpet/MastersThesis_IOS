# Zoo Prague iOS application
An iOS and iPadOS application for visitors of Zoo Prague which is part of my Master's thesis. It uses data collected by the [created server](https://github.com/budikpet/MastersThesis_Server).

## Features
- Zoo Prague lexicon which contains information about all animals here.
    - can be filtered;
    - can be used to find a place where the animal is.
- A map of Zoo Prague which is integrated with the lexicon.
    - fully offline and constrained to Zoo Prague and surrounding area;
    - shows locations of animals;
    - makes it possible to navigate to a point on the map or a specific location.

## How to build manually
API keys for automated localization through ACKLocalization need to be provided. Use [official documentation](https://github.com/AckeeCZ/ACKLocalization#use-with-service-account) to prepare the library itself and a [step-by-step](https://cloud.google.com/iam/docs/creating-managing-service-account-keys) guide for creating Google development console Service account key. It mainly requires the service account specified through the file *Localization/localizationServiceAccount.json.fill* that is downloaded from the Google development console.
