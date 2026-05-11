import React from "react";
import { Routes, Route } from "react-router-dom";
import { Layout } from "./components/Layout.js";
import { Dashboard } from "./pages/Dashboard.js";
import { Search } from "./pages/Search.js";
import { Browse } from "./pages/Browse.js";
import { Thread } from "./pages/Thread.js";
import { Edit } from "./pages/Edit.js";
import { Convert } from "./pages/Convert.js";
import { Datasets } from "./pages/Datasets.js";
import { DatasetDetail } from "./pages/DatasetDetail.js";
import { Settings } from "./pages/Settings.js";

export function App() {
  return (
    <Routes>
      <Route element={<Layout />}>
        <Route index element={<Dashboard />} />
        <Route path="search" element={<Search />} />
        <Route path="browse" element={<Browse />} />
        <Route path="thread/:id" element={<Thread />} />
        <Route path="thread/:id/edit" element={<Edit />} />
        <Route path="thread/:id/convert" element={<Convert />} />
        <Route path="datasets" element={<Datasets />} />
        <Route path="datasets/:name" element={<DatasetDetail />} />
        <Route path="settings" element={<Settings />} />
      </Route>
    </Routes>
  );
}
