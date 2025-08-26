import { Controller } from "@hotwired/stimulus";
import Swiper from 'swiper';
import { Navigation, Autoplay } from 'swiper/modules';

export default class extends Controller {
    connect() {
      this.swiper = new Swiper('.games_swiper', {
        modules: [Navigation, Autoplay],

        // Optional parameters
        slidesPerView: 12,
        spaceBetween: 5,
        breakpoints: {
          // when window width is >= 320px
          320: {
            slidesPerView: 3,
            spaceBetween: 3
          },
          // when window width is >= 480px
          480: {
            slidesPerView: 4,
            spaceBetween: 5
          },
          // when window width is >= 768px
          768: {
            slidesPerView: 6,
            spaceBetween: 5
          },
          // when window width is >= 992px
          992: {
            slidesPerView: 8,
            spaceBetween: 5
          },
          // when window width is >= 1200px
          1200: {
            slidesPerView: 10,
            spaceBetween: 5
          },
          // when window width is >= 1440px
          1440: {
            slidesPerView: 12,
            spaceBetween: 5
          }
        },
        loop: true,
        autoplay: {
          delay: 5000,
        },

        // Navigation arrows
        navigation: {
          nextEl: '.swiper-button-next',
          prevEl: '.swiper-button-prev',
        },
      });
    }
}
