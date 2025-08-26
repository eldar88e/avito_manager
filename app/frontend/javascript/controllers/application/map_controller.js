import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
    static targets = ["map", "addresses"];

    connect() {
        ymaps.ready(() => {
            this.initMap();
            this.processAddresses();
        });
    }

    initMap() {
        this.myMap = new ymaps.Map(this.mapTarget, {
            center: [55.753994, 37.622093],
            zoom: 10,
            controls: ['zoomControl', 'fullscreenControl']
        });
    }

    processAddresses() {
        const addresses = this.addressesTarget.querySelectorAll('span');
        addresses.forEach((address) => {
            const cityName = address.textContent.trim();
            this.addCityToMap(cityName);
        });
    }

    addCityToMap(cityName) {
        if (!this.myMap) return console.error('Карта еще не загружена');

        ymaps.geocode(cityName, {
            results: 1
        }).then((res) => {
            let firstGeoObject = res.geoObjects.get(0),
                coords = firstGeoObject.geometry.getCoordinates(),
                bounds = firstGeoObject.properties.get('boundedBy');
            firstGeoObject.options.set('preset', 'islands#darkBlueDotIconWithCaption');
            firstGeoObject.properties.set('iconCaption', firstGeoObject.getAddressLine());

            this.myMap.geoObjects.add(firstGeoObject);
            this.myMap.setBounds(this.myMap.geoObjects.getBounds(), {
                checkZoomRange: true
            });
        });
    }
}
