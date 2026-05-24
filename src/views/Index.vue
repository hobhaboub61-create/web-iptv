<template>
  <div class="video-container">
    <video-player
      :src="value"
      :tracks="tracks"
      :languages="languages"
      fluid
      class="video-player vjs-big-play-centered"
    />
    <div v-if="errorMessage" class="error-overlay">
      <div class="error-content">
        <p class="error-icon">!</p>
        <p>{{ errorMessage }}</p>
        <button v-if="canRetry" @click="retryStream" class="retry-btn">{{ retryText }}</button>
      </div>
    </div>
  </div>
</template>

<script setup>
import en from "video.js/dist/lang/en.json";
import fr from "video.js/dist/lang/fr.json";
import { computed, onBeforeUnmount, onMounted, ref, watch } from "vue";
import { useI18n } from "../i18n/index.js";
import videojs from "video.js";

const { t, locale } = useI18n();
const props = defineProps(["value", "track"]);

const errorMessage = ref("");
const canRetry = ref(false);
let retryTimeout = null;
let retryCount = 0;
let player = null;

const retryText = computed(() => locale.value === "fr" ? "Réessayer" : "Retry");

const tracks = computed(() => {
  return (props.track && [
    { src: props.track, srclang: "en", label: "default", mode: "showing" },
  ]) || undefined;
});

const languages = ref({ en, fr });

function clearError() {
  errorMessage.value = "";
  canRetry.value = false;
}

function showError(msg, allowRetry = true) {
  errorMessage.value = msg;
  canRetry.value = allowRetry && retryCount < 3;
}

function loadSource(src) {
  if (!player || !src) return;
  clearError();
  player.src({ src, type: "application/x-mpegURL" });
  player.play();
}

function retryStream() {
  if (retryCount >= 3) {
    showError(locale.value === "fr" ? "Nombre max de tentatives atteint" : "Max retries reached", false);
    return;
  }
  retryCount++;
  clearError();
  if (props.value && player) loadSource(props.value);
}

onMounted(() => {
  player = videojs.getAllPlayers()[0];
  if (!player) return;

  player.language(locale.value === "fr" ? "fr" : "en");

  player.on("error", () => {
    const error = player.error();
    if (!error) return;
    const codes = {
      1: locale.value === "fr" ? "Chargement interrompu" : "Loading aborted",
      2: locale.value === "fr" ? "Erreur réseau" : "Network error",
      4: locale.value === "fr" ? "Source non supportée" : "Source not supported",
    };
    const msg = codes[error.code] || (locale.value === "fr" ? "Erreur de lecture" : "Playback error");

    if (error.code === 2 && retryCount < 3) {
      retryCount++;
      showError(`${msg} - ${locale.value === "fr" ? "Nouvelle tentative" : "Retrying"}...`, false);
      retryTimeout = setTimeout(() => {
        if (props.value && player) loadSource(props.value);
      }, 3000);
    } else {
      showError(msg, error.code !== 4);
    }
  });

  player.on("playing", () => {
    clearError();
    retryCount = 0;
  });

  watch(locale, (newLocale) => {
    player.language(newLocale === "fr" ? "fr" : "en");
  });

  watch(() => props.value, (newValue) => {
    if (newValue && player) {
      retryCount = 0;
      loadSource(newValue);
    }
  });
});

onBeforeUnmount(() => {
  if (retryTimeout) clearTimeout(retryTimeout);
});
</script>

<style scoped>
.video-container {
  width: 100%;
  height: calc(100vh - 0px);
  height: calc(100dvh - 0px);
  position: relative;
  background: #000;
}

.video-container :deep(.video-js) {
  width: 100%;
  height: 100%;
}

.error-overlay {
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0, 0, 0, 0.85);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 10;
}

.error-content {
  text-align: center;
  color: var(--text-primary);
  padding: 2rem;
}

.error-icon {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 48px;
  height: 48px;
  border-radius: 50%;
  background: var(--danger);
  font-size: 24px;
  font-weight: bold;
  margin: 0 auto 1rem;
}

.error-content p {
  margin: 0 0 1rem;
  font-size: 1.1rem;
}

.retry-btn {
  background: var(--primary);
  color: #fff;
  border: none;
  padding: 0.75rem 1.5rem;
  border-radius: 6px;
  font-size: 1rem;
  cursor: pointer;
  transition: background 0.2s;
}

.retry-btn:hover {
  background: var(--primary-hover);
}
</style>
