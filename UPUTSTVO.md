# Prva Vest – Android aplikacija (verzija 1)

U folderu `lib` je ceo kod aplikacije. Vesti, slike, kategorije i logo
aplikacija povlači direktno sa prvavest.com, pa svaka nova vest odmah
stiže i u aplikaciju.

## Pokretanje na Mac-u (Terminal)

1. Raspakuj ovu arhivu, npr. u folder `Documents`.
2. Otvori Terminal i uđi u folder:

       cd ~/Documents/prvavest

3. Napravi Android delove projekta (Flutter ih sam generiše):

       flutter create --org com.prvavest --project-name prvavest --platforms android .

   (tačka na kraju je bitna; znači "ovaj folder")

4. Dodaj pakete koje aplikacija koristi:

       flutter pub add http cached_network_image flutter_widget_from_html_core shared_preferences url_launcher

5. Poveži telefon kablom (uključeno USB debagovanje) i pokreni:

       flutter run

Prvo pokretanje traje nekoliko minuta. Posle toga, dok aplikacija radi,
izmene u kodu vidiš odmah ako u Terminalu pritisneš `r`.

## Šta je gde

- `lib/config.dart` – adresa sajta, logo, boja, redosled kategorija
- `lib/api.dart` – preuzimanje vesti sa sajta
- `lib/models.dart` – podaci o vesti (naslov, slika, autor, datum)
- `lib/screens/` – ekrani: Početna, Članak, Pretraga, Sačuvano
- `lib/widgets.dart` – kartice vesti, logo, slike
- `lib/saved_store.dart` – čuvanje omiljenih vesti u telefonu
