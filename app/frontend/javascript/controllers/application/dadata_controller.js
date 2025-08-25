import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = [
    "suggestions",
    "suggestions_street",
    "address",
    "street",
    "post_code",
    "home",
    "apartment",
    "build",
  ];

  connect() {
    this.city = null;
    this.street = null;
  }

  search(event) {
    const query = event.target.value.trim();
    let suggestions = this.suggestionsTarget;
    this.formConnection(query, suggestions);
    this.suggestions_streetTarget.style.display = "none";
    this.suggestions_streetTarget.parentElement.style.display = "none";
  }

  search_street(event) {
    let query = event.target.value.trim();
    let suggestions = this.suggestions_streetTarget;
    this.formConnection(query, suggestions, true);
  }

  formConnection(query, suggestions, prefixStreet = false) {
    if (!query) {
      suggestions.style.display = "none";
      suggestions.parentElement.style.display = "none";
      suggestions.textContent = "";
      return;
    }
    const entity = prefixStreet ? "street" : "city";
    if (this[entity] === query) {
      suggestions.style.display = "block";
      suggestions.parentElement.style.display = "block";
      return;
    }

    this[entity] = query;

    if (prefixStreet) {
      let address = this.addressTarget.value.trim();
      if (address.length > 1) {
        query = `${address} ${query}`;
      }
    }

    let options = {
      method: "POST",
      mode: "cors",
      headers: {
        "Content-Type": "application/json",
        Accept: "application/json",
        Authorization: "Token " + dadata_token,
      },
      body: JSON.stringify({ query: query }),
    };

    this.fetchDadata(options, suggestions);
  }

  pullData(data, suggestions) {
    suggestions.textContent = "";
    if (data.length > 0) {
      this.append("Выберите один из вариантов...", suggestions);
      window.suggestions_cache = data;
      data.forEach((value, index) => {
        this.append(value["unrestricted_value"], suggestions, index);
      });
      suggestions.style.display = "block";
      suggestions.parentElement.style.display = "block";
    } else {
      suggestions.style.display = "none";
      suggestions.parentElement.style.display = "none";
    }
  }

  append(text, suggestions, id = false) {
    let suggestionElement = document.createElement("div");
    suggestionElement.classList.add("suggestion-item");
    if (id !== false) {
      suggestionElement.setAttribute("data-dadata-id-value", id);
      suggestionElement.setAttribute("data-action", "click->dadata#setAddress");
    }
    suggestionElement.textContent = text;
    suggestions.appendChild(suggestionElement);
  }

  setAddress(event) {
    const idValue = event.target.dataset.dadataIdValue;
    const address = suggestions_cache[idValue]["data"];

    if (address["region_with_type"]) {
      //this.addressTarget.value = address['region_with_type'];
      if (address["area_with_type"]) {
        this.addressTarget.value += `, ${address["area_with_type"]}`;
      }
      if (
        address["city_with_type"] &&
        address["region_with_type"] !== address["city_with_type"]
      ) {
        this.addressTarget.value += `, ${address["city_with_type"]}`;
      }
      if (address["settlement_with_type"]) {
        this.addressTarget.value += `, ${address["settlement_with_type"]}`;
      }
    } else {
      this.addressTarget.value = "";
    }

    this.streetTarget.value = address["street_with_type"]
      ? address["street_with_type"]
      : "";
    //this.post_codeTarget.value = address['postal_code'] ? address['postal_code'] : "";
    this.homeTarget.value = address["house"] ? address["house"] : "";
    this.apartmentTarget.value = address["flat"] ? address["flat"] : "";
    this.buildTarget.value = address["stead"] ? address["stead"] : "";

    // this.suggestionsTarget.style.display = "none";
    // this.suggestionsTarget.parentElement.style.display = "none";
    // this.suggestions_streetTarget.style.display = "none";
    // this.suggestions_streetTarget.parentElement.style.display = "none";
  }

  fetchDadata(options, suggestions) {
    const url =
      "//suggestions.dadata.ru/suggestions/api/4_1/rs/suggest/address";
    fetch(url, options)
      .then((response) => {
        if (!response.ok) {
          throw new Error(`HTTP error! Status: ${response.status}`);
        }
        return response.json();
      })
      .then((data) => {
        this.pullData(data.suggestions, suggestions);
      })
      .catch((error) => {
        console.error("Error fetching suggestions:", error);
      });
  }

  hidden() {
    setTimeout(() => {
      this.suggestionsTarget.style.display = "none";
      this.suggestionsTarget.parentElement.style.display = "none";
    }, 300);
  }

  hiddenStreet() {
    setTimeout(() => {
      this.suggestions_streetTarget.style.display = "none";
      this.suggestions_streetTarget.parentElement.style.display = "none";
    }, 300);
  }
}
