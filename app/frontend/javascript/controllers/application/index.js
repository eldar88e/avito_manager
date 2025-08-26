import { application } from "./application";

const controllers = import.meta.glob("./**/*_controller.js", { eager: true });

Object.entries(controllers).forEach(([path, module]) => {
  const controllerName = path
    .replace(/^\.\//, "") // Remove leading ./
    .replace(/_controller\.js$/, "") // Remove _controller.js
    .replace(/\//g, "--") // Replace slashes with --
    .replace(/_/g, "-"); // Replace underscores with dashes

  application.register(controllerName, module.default);
});
