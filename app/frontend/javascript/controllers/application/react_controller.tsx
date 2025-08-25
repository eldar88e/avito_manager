// For connect react components to stimulus
// Use:
// data: {
//   controller: "react",
//   "react-name-value": "ConnectName",
//   "react-props-value": { count: 10 }.to_json
// }

import { Controller } from "@hotwired/stimulus";
import React from "react";
import { createRoot, Root as RootType } from "react-dom/client";
import * as Components from "../../../components";

export default class extends Controller {
  static values = { name: String, props: Object };

  declare nameValue: string;
  declare propsValue: Record<string, any>;
  private root?: RootType;

  connect() {
    const Component = (Components as any)[this.nameValue];
    if (!Component) {
      console.error(`React component "${this.nameValue}" not found`);
      return;
    }
    this.root = createRoot(this.element);
    this.root.render(<Component {...this.propsValue} />);
  }

  disconnect() {
    this.root?.unmount();
  }
}
