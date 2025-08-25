import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  connect() {
    this.observer = new IntersectionObserver((entries) => {
      entries.forEach((entry) => {
        if (entry.isIntersecting) {
          setTimeout(() => {
            this.loadMore();
          }, 800);
        }
      });
    });
    this.observer.observe(this.element);
  }

  loadMore() {
    const url = this.data.get("url");
    if (url) {
      fetch(url, { headers: { Accept: "text/vnd.turbo-stream.html" } })
        .then((response) => response.text())
        .then((html) => {
          this.element.insertAdjacentHTML("beforebegin", html);
        })
        .catch((error) =>
          console.error("Ошибка загрузки следующей страницы:", error),
        );
    }
  }

  disconnect() {
    this.observer.disconnect();
  }
}
