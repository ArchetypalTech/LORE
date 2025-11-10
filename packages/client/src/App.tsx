import { Route, Switch } from "wouter";
import "./styles/index.css";
import { Client } from "./client/client";
import { Editor } from "./editor/editor";
import DojoStore from "@lib/stores/dojo.store.ts";

const App = () => {
  return (
    <Switch>
      <Route
        path="/editor"
        component={() => {
          DojoStore().setAppMode("editor");
          return <Editor />;
        }}
      />
      <Route
        component={() => {
          DojoStore().setAppMode("client");
          return <Client />;
        }}
      />
    </Switch>
  );
};

export default App;
