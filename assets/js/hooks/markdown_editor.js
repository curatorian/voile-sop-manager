// MarkdownEditor Hook for EasyMDE Integration
// This hook initializes the EasyMDE markdown editor on textarea elements

const MarkdownEditor = {
  mounted() {
    const fieldName = this.el.dataset.fieldName;
    const initialValue = this.el.dataset.initialValue || "";

    // Find or create the textarea inside this hook element
    let textarea = this.el.querySelector("textarea");
    if (!textarea) {
      textarea = document.createElement("textarea");
      textarea.name = fieldName;
      this.el.appendChild(textarea);
    }

    textarea.value = initialValue;
    textarea.style.display = "block"; // EasyMDE needs it visible to init

    this.editor = new EasyMDE({
      element: textarea,
      spellChecker: false,
      autosave: { enabled: false },
      toolbar: [
        "bold",
        "italic",
        "heading",
        "|",
        "unordered-list",
        "ordered-list",
        "|",
        "link",
        "table",
        "horizontal-rule",
        "|",
        "preview",
        "side-by-side",
        "fullscreen",
        "|",
        "guide",
      ],
      placeholder: "Write in Markdown...",
      initialValue: initialValue,
      minHeight: "250px",
      status: ["autosave", "lines", "words"],
      previewRender: (plainText) => {
        // Custom preview rendering if needed
        return this.editor.markdown(plainText);
      },
    });

    // Sync EasyMDE content back to the textarea so Phoenix form picks it up
    this.editor.codemirror.on("change", () => {
      textarea.value = this.editor.value();

      // Dispatch an input event so phx-change works
      textarea.dispatchEvent(new Event("input", { bubbles: true }));
    });

    // Store reference for cleanup
    this.textarea = textarea;
  },

  updated() {
    // If LiveView patches the DOM, keep the editor value intact
    // (do nothing — EasyMDE manages its own DOM)
    const newValue = this.el.dataset.initialValue;
    if (
      newValue !== undefined &&
      this.editor &&
      this.editor.value() !== newValue
    ) {
      this.editor.value(newValue);
    }
  },

  destroyed() {
    if (this.editor) {
      this.editor.toTextArea();
      this.editor = null;
    }
  },
};

export default MarkdownEditor;
