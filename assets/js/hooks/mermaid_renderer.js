// MermaidRenderer Hook for Mermaid diagram rendering
// This hook initializes Mermaid.js to render diagrams in SOP content

const MermaidRenderer = {
  mounted() {
    this.renderMermaidDiagrams();
  },

  updated() {
    this.renderMermaidDiagrams();
  },

  renderMermaidDiagrams() {
    // Check if Mermaid is loaded
    if (typeof mermaid === "undefined") {
      console.warn("Mermaid.js not loaded. Add the CDN script to your layout.");
      return;
    }

    // Find all mermaid diagrams in this element
    const mermaidElements = this.el.querySelectorAll(".mermaid");

    if (mermaidElements.length === 0) {
      return;
    }

    // Initialize mermaid with configuration
    mermaid.initialize({
      startOnLoad: false,
      theme: "default",
      securityLevel: "loose",
      fontFamily: "inherit",
      flowchart: {
        useMaxWidth: true,
        htmlLabels: true,
        curve: "basis",
      },
      sequence: {
        useMaxWidth: true,
        diagramMarginX: 50,
        diagramMarginY: 10,
        actorMargin: 50,
        width: 150,
        height: 65,
      },
      gantt: {
        useMaxWidth: true,
        leftPadding: 75,
        gridLineStartPadding: 35,
        barHeight: 20,
        barGap: 4,
        topPadding: 50,
      },
    });

    // Render each mermaid diagram
    mermaidElements.forEach(async (element, index) => {
      try {
        // Get the diagram code
        const code = element.textContent.trim();

        // Generate unique ID
        const id = `mermaid-${Date.now()}-${index}`;

        // Render the diagram
        const { svg } = await mermaid.render(id, code);

        // Replace the pre content with the SVG
        element.innerHTML = svg;
      } catch (error) {
        console.error("Mermaid rendering error:", error);
        element.innerHTML = `
          <div class="text-red-500 p-4 border border-red-300 rounded bg-red-50">
            <p class="font-semibold">Mermaid Diagram Error</p>
            <p class="text-sm">${error.message || "Could not render diagram"}</p>
            <pre class="text-xs mt-2 overflow-x-auto">${element.textContent}</pre>
          </div>
        `;
      }
    });
  },
};

export default MermaidRenderer;
