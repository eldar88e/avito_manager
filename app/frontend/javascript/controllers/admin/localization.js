import { I18n } from "i18n-js";
import ru from "./ru.json";

export default class Localization {
  constructor(locale = "ru") {
    this.i18n = new I18n();
    this.i18n.translations = { ru };
    this.i18n.locale = locale;
  }

  getPluralForm(count) {
    const mod10 = count % 10;
    const mod100 = count % 100;

    if (mod10 === 1 && mod100 !== 11) {
      return "one";
    } else if (mod10 >= 2 && mod10 <= 4 && (mod100 < 10 || mod100 >= 20)) {
      return "few";
    } else {
      return "many";
    }
  }

  t(key, options = {}) {
    return this.i18n.t(key, options);
  }

  orderTitle(count) {
    const pluralKey = this.getPluralForm(count);
    return `${count} ${this.t(`order.${pluralKey}`, { count })}`;
  }
}
