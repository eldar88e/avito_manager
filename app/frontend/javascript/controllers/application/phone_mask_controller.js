import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["phoneNumber"];

  connect() {
    // const valueSize = this.phoneNumberTarget.value.trim().length;
    // if (valueSize !== 18 && valueSize > 0) {
    //   this.mask();
    //   setTimeout(() => {
    //     this.check();
    //   }, 2000);
    // }
  }

  startMask() {
    if (this.phoneNumberTarget.value.trim().length === 0) {
      //this.check();
      this.phoneNumberTarget.value = "+7 (";
    }
  }

  mask() {
    this.phoneNumberTarget.classList.remove("error");
    this.phoneNumberTarget.setCustomValidity("");
    let rawValue = this.phoneNumberTarget.value.replace(/\D/g, "");
    if (rawValue.startsWith("8")) {
      rawValue = "7" + rawValue.slice(1);
    } else if (!rawValue.startsWith("7") && rawValue.length > 0) {
      rawValue = "7" + rawValue;
    }

    const length = rawValue.length;
    let formattedValue = "";

    if (length > 0) formattedValue += "+7";
    if (length > 1) formattedValue += " (" + rawValue.slice(1, 4);
    if (length > 4) formattedValue += ") " + rawValue.slice(4, 7);
    if (length > 7) formattedValue += "-" + rawValue.slice(7, 9);
    if (length > 9) formattedValue += "-" + rawValue.slice(9, 11);

    this.phoneNumberTarget.value = formattedValue.substring(0, 18);
  }

  check(event) {
    let input = this.phoneNumberTarget;
    if (input.value.length < 18) {
      event.preventDefault();
      input.setCustomValidity("Введите полный номер телефона.");
      input.classList.add("error");
    } else {
      input.setCustomValidity("");
      input.classList.remove("error");
    }
    //input.reportValidity();
  }

  clear() {
    if (this.phoneNumberTarget.value.length < 18)
      this.phoneNumberTarget.value = "";
  }
}
