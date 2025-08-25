import { Controller } from "@hotwired/stimulus";
import ApexCharts from "apexcharts";

export default class extends Controller {
  static targets = ["chart"];
  static values = { time: { type: Number, default: 1000 } };

  connect() {
    setTimeout(() => {
      this.last_week();
    }, this.timeValue);
  }

  last_week() {
    this.fetchData();
  }

  last_month() {
    this.fetchData("&period=month");
  }

  last_year() {
    this.fetchData("&period=year");
  }

  all() {
    this.fetchData("&period=all");
  }

  async fetchData(params = "") {
    const response = await fetch(`/admin/analytics?type=sold${params}`);
    const data = await response.json();

    this.renderChart(data.dates, data.solds);
  }

  renderChart(dates, revenues) {
    const options = {
      chart: {
        type: "area",
        height: 320,
      },
      stroke: {
        curve: "smooth",
        colors: ["#1C64F2"],
      },
      fill: {
        type: "gradient", // Используем градиент для заливки
        gradient: {
          opacityFrom: 0.55,
          opacityTo: 0,
          shade: "#1C64F2",
          gradientToColors: ["#1C64F2"],
        },
      },
      dataLabels: {
        enabled: false,
      },
      grid: {
        show: false,
      },
      series: [
        {
          name: "Продажи",
          data: revenues,
        },
      ],
      xaxis: {
        categories: dates,
        title: {
          //text: "Дата",
        },
        labels: {
          style: {
            colors: "rgb(156, 163, 175);",
            fontSize: "14px",
            fontWeight: 700,
          },
        },
      },
      tooltip: {
        y: {
          formatter: function (value) {
            return `${value} шт.`;
          },
        },
      },
    };

    this.chartTarget.textContent = "";
    const chart = new ApexCharts(this.chartTarget, options);
    chart.render();
  }
}
