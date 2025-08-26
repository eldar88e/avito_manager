import { Controller } from "@hotwired/stimulus"
import {Fancybox} from "@fancyapps/ui";

export default class extends Controller {
    connect() {
        Fancybox.bind("[data-fancybox]");
    }
}
