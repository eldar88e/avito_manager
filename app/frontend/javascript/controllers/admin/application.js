import { Application } from "@hotwired/stimulus";

const application = Application.start();

// Configure Stimulus development experience
// application.debug = import.meta.env.MODE === 'development'
application.debug = false;
window.Stimulus = application;

export { application };
