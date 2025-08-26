import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    connect() {
        this.scroller();
    }

    showLeftBar(event) {
        let parentElement = event.target.parentElement.parentElement;
        if (parentElement.style.transform == '') {
            parentElement.style.transform = "rotate(180deg)";
        } else {
            parentElement.style.transform = "";
        }
        document.querySelector('.left-bar').classList.toggle('hidden-left-bar');
    }

    showMainMenu() {
        document.querySelector('.navbar-toggler').click();
    }

    up() {
        window.scrollTo({
            top: 0,
            behavior: 'smooth'
        });
    }

    scroller() {
        // $(window).scroll(function() {
        //     if ($(this).scrollTop() > 300) {
        //         $('#scroller').fadeIn();
        //     } else {
        //         $('#scroller').fadeOut();
        //     }
        // });

        window.addEventListener('scroll', () => {
            const scrollerElement = document.getElementById('scroller');
            if (window.scrollY > 300) {
                scrollerElement.style.visibility = 'visible';
                scrollerElement.style.opacity = 1;
            } else {
                scrollerElement.style.opacity = 0;
                setTimeout(() => {
                    scrollerElement.style.visibility = 'hidden';
                }, 400); // Задержка для плавного исчезновения
            }
        });
    }
}
