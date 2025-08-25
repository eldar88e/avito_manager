import { Controller } from "@hotwired/stimulus";
import Swiper from "swiper/bundle";
import "swiper/css/bundle";

export default class extends Controller {
  static targets = ["container"];

  connect() {
    const randomDelay = () =>
      Math.floor(Math.random() * (8000 - 5000 + 1)) + 5000;

    this.swiper = new Swiper(this.containerTarget, {
      loop: true,
      slidesPerView: 4,
      spaceBetween: 0,
      pagination: {
        el: ".swiper-pagination",
        clickable: true,
      },
      navigation: {
        nextEl: ".swiper-button-next",
        prevEl: ".swiper-button-prev",
      },
      autoplay: {
        delay: randomDelay(),
        disableOnInteraction: false,
      },
      breakpoints: {
        0: {
          slidesPerView: 1,
          spaceBetween: 0,
        },
        320: {
          slidesPerView: 1.5,
          centeredSlides: true,
        },
        576: {
          slidesPerView: 2,
        },
        768: {
          slidesPerView: 3,
        },
        1024: {
          slidesPerView: 3.5,
          centeredSlides: true,
        },
        1536: {
          slidesPerView: 4,
        },
        1900: { slidesPerView: 5 },
      },
    });
  }

  disconnect() {
    this.swiper.destroy();
  }
}
