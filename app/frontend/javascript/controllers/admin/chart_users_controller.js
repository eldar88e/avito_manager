import { Controller } from "@hotwired/stimulus";
import ApexCharts from "apexcharts";
// import Localization from "./localization";

export default class extends Controller {
  static targets = ["chart"];
  static values = { time: { type: Number, default: 1600 } };

  connect() {
    setTimeout(() => {
      this.last_week();
    }, this.timeValue);
  }

  last_week() {
    this.fetchRevenueData();
  }

  last_month() {
    this.fetchRevenueData("&period=month");
  }

  last_year() {
    this.fetchRevenueData("&period=year");
  }

  all() {
    this.fetchRevenueData("&period=all");
  }

  async fetchRevenueData(params = "") {
    const response = await fetch(`/admin/analytics?type=users${params}`);
    const data = await response.json();

    this.renderChart(data.dates, data.users);
  }

  renderChart(dates, users) {
    const options = {
      chart: {
        type: "area",
        height: 350,
      },
      stroke: {
        curve: "smooth",
        colors: ["#0e9f6e"],
      },
      markers: {
        size: 6,
        colors: ["#0e9f6e"],
        strokeColors: "#eef7ff",
        strokeWidth: 2,
        hover: {
          size: 8,
        },
      },
      grid: {
        show: false,
        //borderColor: '#374151',
        //strokeDashArray: 1,
      },
      fill: {
        type: "gradient",
        gradient: {
          opacityFrom: 0.55,
          opacityTo: 0,
          shade: "#0e9f6e",
          gradientToColors: ["#0e9f6e"],
        },
      },
      dataLabels: {
        enabled: false,
      },
      series: [
        {
          name: "Пользователей",
          data: users,
        },
      ],
      xaxis: {
        categories: dates,
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
            return value;
          },
        },
      },
    };

    this.chartTarget.textContent = "";
    const chart = new ApexCharts(this.chartTarget, options);
    chart.render();
  }
}
