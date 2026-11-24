"use strict";

document.querySelectorAll("form[data-confirm]").forEach((form) => {
  form.addEventListener("submit", (event) => {
    if (!window.confirm(form.dataset.confirm)) event.preventDefault();
  });
});

const filter = document.getElementById("semester-filter");
if (filter) {
  filter.addEventListener("change", () => {
    let count = 0;
    document.querySelectorAll(".course-card[data-semester]").forEach((card) => {
      card.hidden =
        filter.value !== "" && card.dataset.semester !== filter.value;
      if (!card.hidden) count += 1;
    });
    document.getElementById("course-count").textContent =
      `${count} course${count === 1 ? "" : "s"} available`;
    document.getElementById("no-courses").hidden = count !== 0;
  });
}

const dialog = document.getElementById("statistics-dialog");
if (dialog) {
  let activeRequest;
  document
    .getElementById("close-statistics")
    .addEventListener("click", () => dialog.close());
  dialog.addEventListener("click", (event) => {
    if (event.target === dialog) dialog.close();
  });
  dialog.addEventListener("close", () => activeRequest?.abort());
  document.querySelectorAll("[data-statistics-url]").forEach((link) => {
    link.addEventListener("click", async (event) => {
      event.preventDefault();
      activeRequest?.abort();
      activeRequest = new AbortController();
      document.getElementById("statistics-title").textContent =
        link.dataset.courseName;
      const content = document.getElementById("statistics-content");
      content.textContent = "Loading statistics…";
      dialog.showModal();
      try {
        const response = await fetch(link.dataset.statisticsUrl, {
          headers: { Accept: "application/json" },
          signal: activeRequest.signal,
        });
        if (!response.ok)
          throw new Error(
            "Could not load statistics. Close this window and try again.",
          );
        const stats = await response.json();
        const list = document.createElement("dl");
        list.className = "metric-grid";
        const labels = {
          count: "Completed results",
          min: "Minimum",
          max: "Maximum",
          mean: "Mean",
          standard_deviation: "Std. deviation",
        };
        Object.entries(labels).forEach(([key, label]) => {
          const item = document.createElement("div");
          item.className = "metric";
          const term = document.createElement("dt");
          const value = document.createElement("dd");
          term.textContent = label;
          value.textContent = stats[key] ?? "—";
          item.append(term, value);
          list.append(item);
        });
        content.replaceChildren(list);
        if (stats.count === 0) {
          const note = document.createElement("p");
          note.textContent =
            "No completed results yet. Statistics appear once all assessments have been graded.";
          content.append(note);
        }
      } catch (error) {
        if (error.name !== "AbortError") content.textContent = error.message;
      }
    });
  });
}
