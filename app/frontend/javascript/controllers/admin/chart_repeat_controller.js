import { Controller } from "@hotwired/stimulus";
import ApexCharts from "apexcharts";
import Localization from "./localization";

export default class extends Controller {
  static targets = ["chart"];
  static values = { time: { type: Number, default: 1400 } };

  connect() {
    setTimeout(() => {
      this.localization = new Localization("ru");
      this.last_week();
    }, this.timeValue);
  }

  async last_week() {
    await this.fetchRevenueData();
  }

  async last_month() {
    await this.fetchRevenueData("&period=month");
  }

  async last_year() {
    await this.fetchRevenueData("&period=year");
  }

  async all() {
    await this.fetchRevenueData("&period=all");
  }

  async fetchRevenueData(params = "") {
    const response = await fetch(`/admin/analytics?type=repeat${params}`);
    const data = await response.json();

    await this.renderChart(data[0], data[1] - data[0]);
  }

  async renderChart(repeat, one) {
    const options = {
      series: [repeat, one],
      colors: ["#1C64F2", "#16BDCA"],
      chart: {
        height: 320,
        width: "100%",
        type: "pie",
      },
      stroke: {
        colors: ["white"],
        lineCap: "",
      },
      plotOptions: {
        pie: {
          labels: {
            show: true,
          },
          size: "100%",
          dataLabels: {
            offset: -25,
          },
        },
      },
      labels: ["Повторные", "Единоразовые"],
      dataLabels: {
        enabled: true,
      },
      legend: {
        position: "bottom",
      },
      yaxis: {
        labels: {
          formatter: (value) => this.localization.orderTitle(value),
        },
      },
      xaxis: {
        labels: {
          formatter: (value) => this.localization.orderTitle(value),
        },
        axisTicks: {
          show: false,
        },
        axisBorder: {
          show: false,
        },
      },
    };

    this.chartTarget.textContent = "";
    const chart = new ApexCharts(this.chartTarget, options);

    try {
      await chart.render();
    } catch (error) {
      console.error("Error rendering chart:", error);
    }
  }
}
