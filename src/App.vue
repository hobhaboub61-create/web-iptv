<template>
  <Login v-if="page === 'login'" @authenticated="onAuthenticated" />
  <Register v-else-if="page === 'register'" />
  <template v-else-if="page === 'app'">
    <Nav
      :tvs="tvs"
      :active="url"
      :mode="currentMode"
      :loading="loading"
      :currentCountry="selectedCountry"
      :user="user"
      @switchMode="switchMode"
      @openSettings="showSettings = true"
      @logout="handleLogout"
    />
    <Settings
      :isOpen="showSettings"
      @close="showSettings = false"
      @countryChanged="onCountryChanged"
    />
    <component :is="currentView" :value="url" :track="caption" />
  </template>
</template>

<script setup>
import { listTv } from "./api";
import { parse, suffix } from "./utils/tvlistsupport";
import { ref, computed, onMounted, onUnmounted } from "vue";
import Login from "./views/Login.vue";
import Register from "./views/Register.vue";
import Home from "./views/Index.vue";
import NotFound from "./views/NotFound.vue";
import Nav from "./components/Nav.vue";
import Settings from "./components/Settings.vue";
import { useI18n } from "./i18n/index.js";
import { getSelectedCountry, getPlaylistUrl } from "./utils/geolocation.js";
import { getSession, onAuthChange, logout, isConfigured, getProfile } from "./services/authService.js";

const { t } = useI18n();

const page = ref("login");
const user = ref(null);
const IPTV_URL = "https://iptv-org.github.io/iptv/index.m3u";
const RADIO_URL = "https://iptv-org.github.io/iptv/index.m3u";

const routes = { "/": Home };
let unsub = null;

const currentView = computed(() => {
  return routes[currentPath.value.slice(1).split("?")[0] || "/"] || NotFound;
});

const currentPath = ref(window.location.hash);
const url = ref("");
const tvs = ref([]);
const caption = ref("");
const currentMode = ref("home");
const loading = ref(false);
const showSettings = ref(false);
const selectedCountry = ref(getSelectedCountry());

const playlistCache = {};

function onHashChange() {
  const hash = window.location.hash.slice(1);
  if (hash === "/login") { page.value = "login"; return; }
  if (hash === "/register") { page.value = "register"; return; }
  if (hash === "/" || hash.startsWith("/?")) {
    if (page.value !== "app" && page.value !== "login") return;
    currentPath.value = window.location.hash;
    if (page.value === "app") {
      const searchParams = new URLSearchParams(hash.slice(hash.indexOf("?")));
      const newUrl = searchParams.get("url");
      const newCaption = searchParams.get("caption");
      const mode = searchParams.get("mode");
      if (newUrl) url.value = decodeURIComponent(newUrl);
      if (newCaption) caption.value = decodeURIComponent(newCaption);
      if (mode && mode !== currentMode.value) {
        currentMode.value = mode;
        loadPlaylistForMode(mode, true);
      }
    }
  } else {
    currentPath.value = window.location.hash;
  }
}

function switchMode(mode) {
  currentMode.value = mode;
  loadPlaylistForMode(mode, true);
}

function loadPlaylistForMode(mode, preserveSelection = false) {
  let playlistUrl;
  if (mode === "iptv") {
    playlistUrl = IPTV_URL;
  } else if (mode === "radio") {
    playlistUrl = RADIO_URL;
  } else {
    playlistUrl = getPlaylistUrl(selectedCountry.value, "home");
  }
  loadPlaylist(playlistUrl, mode, preserveSelection);
}

function onCountryChanged(country) {
  selectedCountry.value = country;
}

async function loadPlaylist(playlistUrl, mode = "home", preserveSelection = false) {
  if (!playlistUrl) {
    const params = new URLSearchParams(window.location.hash.replace("#/", ""));
    playlistUrl = params.get("s");
    if (!playlistUrl) {
      if (mode === "iptv") {
        playlistUrl = IPTV_URL;
      } else if (mode === "radio") {
        playlistUrl = RADIO_URL;
      } else {
        playlistUrl = getPlaylistUrl(selectedCountry.value, "home");
      }
    }
  }

  if (playlistCache[playlistUrl]) {
    let cached = playlistCache[playlistUrl];
    if (mode === "radio") {
      cached = filterRadios(cached);
    }
    tvs.value = cached;
    if (!preserveSelection) selectFirstChannel();
    return;
  }

  loading.value = true;
  try {
    let suffixName = suffix(playlistUrl);
    if (suffixName === "m3u8") suffixName = "m3u";
    const d = await listTv(playlistUrl);
    let parsed = parse(d.data, suffixName);
    if (mode === "radio") parsed = filterRadios(parsed);
    playlistCache[playlistUrl] = parsed;
    tvs.value = parsed;
    if (mode === "home") localStorage.setItem("tvlistUrl", playlistUrl);
    if (!preserveSelection) selectFirstChannel();
  } catch (e) {
    tvs.value = [{ name: t("failedToLoad"), isTv: false }];
  } finally {
    loading.value = false;
  }
}

function filterRadios(channels) {
  return channels.filter((channel) => {
    if (!channel.isTv) return true;
    const name = (channel.name || "").toLowerCase();
    const groupTitle = (channel.meta?.["group-title"] || "").toLowerCase();
    return name.includes("radio") || name.includes("fm") ||
           groupTitle.includes("radio") || groupTitle.includes("audio");
  });
}

function selectFirstChannel() {
  if (!url.value || currentMode.value === "iptv") {
    const firstTv = tvs.value.find((t) => t.isTv);
    if (firstTv) {
      url.value = firstTv.url;
      caption.value = firstTv.caption;
    }
  }
}

async function onAuthenticated() {
  try {
    const session = await getSession();
    if (session?.user) {
      const profile = await getProfile(session.user.id);
      user.value = {
        email: session.user.email,
        pseudo: profile?.pseudo || session.user.email?.split('@')[0] || 'User',
      };
      window.location.hash = '#/';
      currentPath.value = window.location.hash;
      page.value = "app";
    }
  } catch {
    page.value = "login";
  }
}

async function handleLogout() {
  await logout();
  user.value = null;
  page.value = "login";
}

onMounted(async () => {
  try {
    if (!isConfigured()) {
      page.value = "login";
      return;
    }

    unsub = onAuthChange((session) => {
      if (session?.user) {
        onAuthenticated();
      } else if (page.value === "app") {
        user.value = null;
        page.value = "login";
      }
    });

    window.addEventListener("hashchange", onHashChange);

    const session = await getSession();
    if (session?.user) {
      await onAuthenticated();
    } else {
      page.value = "login";
    }

    const params = new URLSearchParams(window.location.hash.replace("#/", ""));
    const url0 = params.get("url");
    const mode = params.get("mode") || "home";
    if (url0) url.value = decodeURIComponent(url0);
    caption.value = params.get("caption");
    currentMode.value = mode;
    loadPlaylistForMode(mode);
  } catch {
    page.value = "login";
  }
});

onUnmounted(() => {
  window.removeEventListener("hashchange", onHashChange);
  if (unsub) unsub();
});
</script>
