import { defineConfig } from "vitepress";

export default defineConfig({
  title: "Astra 2D",
  description: "A modular 2D game engine built with Lua and LÖVE.",

  themeConfig: {
    nav: [
      { text: "Home", link: "/" },
      { text: "Getting Started", link: "/getting-started/introduction" },
      { text: "Architecture", link: "/architecture/overview" },
      { text: "Guides", link: "/guides/" },
      { text: "API Reference", link: "/api/" },
    ],

    search: {
      provider: "local",
    },
    sidebar: [
      {
        text: "Getting Started",
        items: [
          { text: "Introduction", link: "/getting-started/introduction" },
          { text: "Installation", link: "/getting-started/installation" },
          { text: "Your First Project", link: "/getting-started/first-project" },
        ],
      },
      {
        text: "Architecture",
        items: [{ text: "Overview", link: "/architecture/overview" }],
      },
      {
        text: "Guides",
        items: [{ text: "Overview", link: "/guides/" }],
      },
      {
        text: "API Reference",
        items: [{ text: "Overview", link: "/api/" }],
      },
    ],

    socialLinks: [
      {
        icon: "github",
        link: "https://github.com/Damet24/lua_engine",
      },
    ],
  },
});
