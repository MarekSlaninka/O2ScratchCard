# O2 Karta

Zadanie pre O2 Slovakia. Stieracia karta s tromi stavmi: nezotretá, zotretá (s odhaleným
kódom) a aktivovaná. SwiftUI, iOS 17, Swift 6, bez externých závislostí.

## Architektúra

Štyri vrstvy, závislosti smerujú dovnútra:

```
Presentation   obrazovky a ich view modely
Application    ActivationManager (drží bežiacu aktiváciu mimo životného cyklu obrazovky)
Domain         ScratchCard, AppVersion, RevealCard, ActivateCard + protokoly hraníc
Data           InMemoryCardRepository, HTTPActivationService
```

Stav karty je enum s asociovaným kódom.
Jeho source of truth je jedine repozitár.
Dependency injection žije v `AppContainer`.
Navigácia ide cez hodnoty `Route`, ktoré na obrazovky mapuje `Route.swift` a `RootView` to
mapovanie aplikuje. Obrazovky sú tým pádom nezávislé a `HomeView` nemusí poznať, ako sa
cieľové view skladá.

Projekt je pokrytý unit aj UI testami. Na accessibility je kladený vysoký nárok: Dynamic
Type až po najväčšie veľkosti, sémantické prvky pre VoiceOver a automatizované
accessibility audity nad každým stavom karty.
Aplikácia a jej UI sú overené aj na iPhone Duo (simulátor, iOS 27.1).
