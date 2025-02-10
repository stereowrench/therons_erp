// See the Tailwind configuration guide for advanced usage
// https://tailwindcss.com/docs/configuration

const colors = require("tailwindcss/colors"); // <-- ADD THIS LINE
const plugin = require("tailwindcss/plugin");
const fs = require("fs");
const path = require("path");

module.exports = {
  content: [
    "../deps/ash_authentication_phoenix/**/*.*ex",
    "./js/**/*.js",
    "../lib/therons_erp_web.ex",
    "../lib/therons_erp_web/**/*.*ex",
    "../deps/live_select/lib/live_select/component.*ex",
    "../deps/petal_components/**/*.*ex", // <-- ADD THIS LINE
  ],
  theme: {
    extend: {
      colors: {
        brand: "#FD4F00",
        primary: colors.blue,
        secondary: colors.pink,
        success: colors.green,
        danger: colors.red,
        warning: colors.yellow,
        info: colors.sky,

        // Options: slate, gray, zinc, neutral, stone
        gray: colors.gray,

        // Logo based reds
        mojo: {
          50: "#fdf4f3",
          100: "#fce7e4",
          200: "#fad4ce",
          300: "#f5b7ac",
          400: "#ee8c7b",
          500: "#e26651",
          600: "#bf432e",
          700: "#ad3b28",
          800: "#8f3425",
          900: "#783024",
          950: "#40160f",
        },
        // Logo based greens
        eagle: {
          50: "#f6f6f4",
          100: "#e5e6df",
          200: "#ccccbb",
          300: "#b7b7a0",
          400: "#9f9d80",
          500: "#918c6f",
          600: "#7f7860",
          700: "#6b6352",
          800: "#595247",
          900: "#4b453c",
          950: "#29251f",
        },
      },
    },
  },
  plugins: [
    require("@tailwindcss/forms"),
    require("@tailwindcss/typography"),
    // Allows prefixing tailwind classes with LiveView classes to add rules
    // only when LiveView classes are applied, for example:
    //
    //     <div class="phx-click-loading:animate-ping">
    //
    plugin(({ addVariant }) =>
      addVariant("phx-click-loading", [
        ".phx-click-loading&",
        ".phx-click-loading &",
      ]),
    ),
    plugin(({ addVariant }) =>
      addVariant("phx-submit-loading", [
        ".phx-submit-loading&",
        ".phx-submit-loading &",
      ]),
    ),
    plugin(({ addVariant }) =>
      addVariant("phx-change-loading", [
        ".phx-change-loading&",
        ".phx-change-loading &",
      ]),
    ),

    // Embeds Heroicons (https://heroicons.com) into your app.css bundle
    // See your `CoreComponents.icon/1` for more information.
    //
    plugin(function ({ matchComponents, theme }) {
      let iconsDir = path.join(__dirname, "../deps/heroicons/optimized");
      let values = {};
      let icons = [
        ["", "/24/outline"],
        ["-solid", "/24/solid"],
        ["-mini", "/20/solid"],
        ["-micro", "/16/solid"],
      ];
      icons.forEach(([suffix, dir]) => {
        fs.readdirSync(path.join(iconsDir, dir)).forEach((file) => {
          let name = path.basename(file, ".svg") + suffix;
          values[name] = { name, fullPath: path.join(iconsDir, dir, file) };
        });
      });
      matchComponents(
        {
          hero: ({ name, fullPath }) => {
            let content = fs
              .readFileSync(fullPath)
              .toString()
              .replace(/\r?\n|\r/g, "");
            let size = theme("spacing.6");
            if (name.endsWith("-mini")) {
              size = theme("spacing.5");
            } else if (name.endsWith("-micro")) {
              size = theme("spacing.4");
            }
            return {
              [`--hero-${name}`]: `url('data:image/svg+xml;utf8,${content}')`,
              "-webkit-mask": `var(--hero-${name})`,
              mask: `var(--hero-${name})`,
              "mask-repeat": "no-repeat",
              "background-color": "currentColor",
              "vertical-align": "middle",
              display: "inline-block",
              width: size,
              height: size,
            };
          },
        },
        { values },
      );
    }),
  ],
};
