import { defineConfig } from "vitepress";

const enNav = [
  { text: "Home", link: "/" },
  { text: "Getting Started", link: "/getting-started/introduction" },
  { text: "Architecture", link: "/architecture/overview" },
  { text: "Guides", link: "/guides/" },
  { text: "API Reference", link: "/api/" },
];

const enSidebar = [
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
];

const esNav = [
  { text: "Inicio", link: "/es/" },
  { text: "Primeros pasos", link: "/es/getting-started/introduction" },
  { text: "Arquitectura", link: "/es/architecture/overview" },
  { text: "Guías", link: "/es/guides/" },
  { text: "Referencia de API", link: "/es/api/" },
];

const esSidebar = [
  {
    text: "Primeros pasos",
    items: [
      { text: "Introducción", link: "/es/getting-started/introduction" },
      { text: "Instalación", link: "/es/getting-started/installation" },
      { text: "Tu primer proyecto", link: "/es/getting-started/first-project" },
    ],
  },
  {
    text: "Arquitectura",
    items: [{ text: "Descripción general", link: "/es/architecture/overview" }],
  },
  {
    text: "Guías",
    items: [{ text: "Descripción general", link: "/es/guides/" }],
  },
  {
    text: "Referencia de API",
    items: [{ text: "Descripción general", link: "/es/api/" }],
  },
];

export default defineConfig({
  title: "Astra 2D",
  description: "A modular 2D game engine built with Lua and LÖVE.",

  locales: {
    root: {
      label: "English",
      lang: "en",
      themeConfig: {
        nav: enNav,
        sidebar: enSidebar,
      },
    },
    es: {
      label: "Español",
      lang: "es",
      link: "/es/",
      title: "Astra 2D",
      description: "Un motor de juego 2D modular creado con Lua y LÖVE.",
      themeConfig: {
        nav: esNav,
        sidebar: esSidebar,
      },
    },
  },

  themeConfig: {
    search: {
      provider: "local",
    },
    socialLinks: [
      {
        icon: "github",
        link: "https://github.com/Damet24/lua_engine",
      },
    ],
  },
});
