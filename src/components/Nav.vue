<template>
  <div class="nav" :class="{ 'nav-open': isOpen }">
    <div class="nav-menu" @click="isOpen = true">
      <img class="logo" src="../assets/logo.svg" alt="Web TV" />
    </div>
    <div class="nav-list-warp" v-show="isOpen">
      <div class="nav-header">
        <span class="nav-title">{{ t('appTitle') }} <img v-if="currentCountryFlagUrl" class="country-indicator" :src="currentCountryFlagUrl" alt="" @error="(e) => e.target.style.display='none'" /></span>
        <div class="nav-header-actions">
          <button
            class="settings-btn"
            @click="$emit('openSettings')"
            :aria-label="t('settings')"
          >&#9881;</button>
          <button class="nav-close" @click="isOpen = false" aria-label="Close menu">&times;</button>
        </div>
      </div>
      <div v-if="user" class="nav-user">
        <span class="nav-user-pseudo">{{ user.pseudo }}</span>
        <button class="nav-logout-btn" @click="$emit('logout')">{{ t('logout') }}</button>
      </div>
      <div class="nav-tabs">
        <a
          class="nav-tab"
          :class="{ 'nav-tab-active': mode === 'home' }"
          href="#/?mode=home"
          @click="$emit('switchMode', 'home')"
        >{{ t('tabHome') }}</a>
        <a
          class="nav-tab"
          :class="{ 'nav-tab-active': mode === 'iptv' }"
          href="#/?mode=iptv"
          @click="$emit('switchMode', 'iptv')"
        >{{ t('tabIptv') }}</a>
        <a
          class="nav-tab"
          :class="{ 'nav-tab-active': mode === 'radio' }"
          href="#/?mode=radio"
          @click="$emit('switchMode', 'radio')"
        >{{ t('tabRadio') }}</a>
      </div>
      <div class="nav-search" v-if="props.tvs.length > 20 || search">
        <div class="search-wrapper">
          <input
            v-model="search"
            type="text"
            :placeholder="t('searchPlaceholder')"
            class="nav-search-input"
          />
          <button
            v-if="search"
            class="search-clear"
            @click="search = ''"
            :aria-label="t('clearSearch') || 'Clear search'"
          >
            ✕
          </button>
        </div>
      </div>
      <div class="nav-loading" v-if="loading">
        <div class="skeleton" v-for="n in 8" :key="n">
          <div class="skeleton-logo"></div>
          <div class="skeleton-line"></div>
        </div>
      </div>
      <template v-else>
        <div class="nav-channel-count" v-if="tvChannelCount > 0 && !search">
          {{ t('channelCount', { count: tvChannelCount }) }}
        </div>
        <div class="nav-no-results" v-if="search && filteredTvs.length === 0">
          {{ t('noResults') }}
        </div>
        <ul class="nav-list">
          <li class="sub-nav" v-for="i in filteredTvs" :key="i.url + i.name">
            <img
              v-if="i.meta && i.meta['tvg-logo']"
              :src="i.meta['tvg-logo']"
              class="tv-logo"
              loading="lazy"
              alt=""
            />
            <a
              v-if="i.isTv"
              :class="{ active: i.url == active }"
              :href="'#/?url=' + encodeURIComponent(i.url) + (i.caption ? '&caption=' + encodeURIComponent(i.caption) : '') + '&mode=' + mode"
              @click="setTitle(i.name)"
            >{{ i.name }}</a>
            <span v-else class="group-label">{{ i.name }}</span>
          </li>
        </ul>
      </template>
    </div>
  </div>
</template>

<script setup>
import { ref, computed } from "vue";
import { useI18n } from "../i18n/index.js";
import { getFlagUrl } from "../utils/geolocation.js";

const { t } = useI18n();

const props = defineProps(["tvs", "active", "mode", "loading", "currentCountry", "user"]);
defineEmits(["switchMode", "openSettings", "logout"]);

const isOpen = ref(false);
const search = ref("");

const currentCountryFlagUrl = computed(() => {
  if (!props.currentCountry) return "";
  return getFlagUrl(props.currentCountry);
});

const tvChannelCount = computed(() => {
  return props.tvs.filter((i) => i.isTv).length;
});

const filteredTvs = computed(() => {
  if (!search.value.trim()) return props.tvs;
  const q = search.value.toLowerCase();
  return props.tvs.filter(
    (i) => i.name && i.name.toLowerCase().includes(q)
  );
});

function setTitle(title) {
  document.title = title + t("titleSuffix");
}
</script>

<style scoped lang="less">
.nav {
  position: absolute;
  top: 0;
  left: 0;
  z-index: 100;
  color: var(--text-primary);

  .nav-menu {
    width: 1.5rem;
    height: 1.5rem;
    padding: 1rem;
    margin: 1rem;
    background: rgba(0, 217, 255, 0.1);
    border: 1px solid rgba(0, 217, 255, 0.2);
    border-radius: 50%;
    cursor: pointer;
    transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
    display: flex;
    align-items: center;
    justify-content: center;
    
    &:hover {
      background: rgba(0, 217, 255, 0.2);
      border-color: var(--primary-neon);
      box-shadow: 0 0 15px rgba(0, 217, 255, 0.3);
      transform: scale(1.1);
    }
    
    .logo {
      width: 1.5rem;
    }
  }

  .nav-list-warp {
    display: none;
    background: linear-gradient(180deg, rgba(10, 10, 20, 0.98) 0%, rgba(15, 10, 25, 0.96) 100%);
    backdrop-filter: blur(15px);
    padding: 0;
    border-radius: 0;
    width: 300px;
    height: 100vh;
    overflow: hidden;
    display: flex;
    flex-direction: column;
    border-right: 1px solid var(--border-color);
  }

  &:not(.nav-open) {
    .nav-list-warp {
      display: none;
    }
  }

  &.nav-open {
    .nav-menu {
      display: none;
    }
    .nav-list-warp {
      display: flex;
    }
  }

  .nav-header {
    display: flex;
    align-items: center;
    justify-content: space-between;
    padding: 1rem 0.8rem 0.8rem 1.2rem;
    min-height: 2.6rem;
    border-bottom: 1px solid var(--border-light);

    .nav-title {
      font-size: 1.1rem;
      font-weight: 700;
      letter-spacing: 0.03em;
      white-space: nowrap;
      min-width: 0;
      display: flex;
      align-items: center;
      gap: 0.6rem;
      background: linear-gradient(135deg, var(--primary-neon) 0%, var(--accent-silver) 100%);
      -webkit-background-clip: text;
      -webkit-text-fill-color: transparent;
      background-clip: text;

      .country-indicator {
        height: 1rem;
        width: auto;
        border-radius: 3px;
        vertical-align: middle;
        border: 1px solid var(--border-color);
      }
    }

    .nav-header-actions {
      display: flex;
      align-items: center;
      gap: 0.6rem;
      flex-shrink: 0;

      .settings-btn {
        background: rgba(0, 217, 255, 0.1);
        border: 1px solid var(--border-color);
        color: var(--primary-neon);
        font-size: 0.95rem;
        padding: 0.4rem 0.6rem;
        border-radius: 8px;
        cursor: pointer;
        transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
        line-height: 1;
        display: flex;
        align-items: center;
        justify-content: center;
        width: 2.2rem;
        height: 2.2rem;

        &:hover {
          background: var(--primary-neon);
          border-color: var(--primary-neon);
          color: var(--bg-darker);
          box-shadow: 0 0 15px rgba(0, 217, 255, 0.3);
          transform: scale(1.05);
        }

        &:active {
          transform: scale(0.95);
        }
      }

      .nav-close {
        background: rgba(255, 255, 255, 0.05);
        border: 1px solid var(--border-light);
        color: var(--text-primary);
        font-size: 1.4rem;
        cursor: pointer;
        padding: 0.3rem 0.5rem;
        border-radius: 6px;
        line-height: 1;
        transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
        font-weight: 300;

        &:hover {
          background: rgba(0, 217, 255, 0.2);
          border-color: var(--primary-neon);
          color: var(--primary-neon);
          transform: rotate(90deg);
        }
      }
    }
  }

  .nav-user {
    display: flex;
    align-items: center;
    justify-content: space-between;
    padding: 0.5rem 1rem;
    border-bottom: 1px solid var(--border-light);
    background: rgba(0, 217, 255, 0.03);

    .nav-user-pseudo {
      font-size: 0.8rem;
      font-weight: 600;
      color: var(--primary-neon);
    }

    .nav-logout-btn {
      background: rgba(239, 68, 68, 0.1);
      border: 1px solid rgba(239, 68, 68, 0.3);
      color: #ef4444;
      font-size: 0.75rem;
      padding: 0.3rem 0.7rem;
      border-radius: 6px;
      cursor: pointer;
      transition: all 0.2s;
      font-weight: 600;

      &:hover {
        background: rgba(239, 68, 68, 0.2);
        border-color: #ef4444;
      }
    }
  }

  .nav-tabs {
    display: flex;
    gap: 0;
    padding: 0.6rem 1rem;
    border-bottom: 1px solid var(--border-light);
  }

  .nav-tab {
    flex: 1;
    text-align: center;
    padding: 0.5rem 0.3rem;
    font-size: 0.7rem;
    font-weight: 700;
    letter-spacing: 0.05em;
    color: var(--text-tertiary);
    text-decoration: none;
    border-bottom: 2px solid transparent;
    transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
    white-space: nowrap;
    min-width: 0;
    overflow: hidden;
    text-overflow: ellipsis;
    text-transform: uppercase;
    
    &:hover {
      color: var(--primary-neon);
      border-bottom-color: rgba(0, 217, 255, 0.3);
    }
  }

  .nav-tab-active {
    color: var(--primary-neon);
    border-bottom-color: var(--primary-neon);
  }

  .nav-search {
    padding: 0.8rem 1rem;
    
    .search-wrapper {
      position: relative;
      display: flex;
      align-items: center;
    }
    
    .nav-search-input {
      width: 100%;
      box-sizing: border-box;
      padding: 0.6rem 2.5rem 0.6rem 0.8rem;
      border-radius: 8px;
      border: 1px solid var(--border-light);
      background: rgba(0, 217, 255, 0.05);
      color: var(--text-primary);
      font-size: 0.85rem;
      outline: none;
      transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
      
      &::placeholder {
        color: var(--text-tertiary);
      }
      
      &:focus {
        border-color: var(--primary-neon);
        background: rgba(0, 217, 255, 0.1);
        box-shadow: 0 0 15px rgba(0, 217, 255, 0.2);
      }
    }
    
    .search-clear {
      position: absolute;
      right: 0.8rem;
      background: none;
      border: none;
      color: var(--text-tertiary);
      cursor: pointer;
      padding: 0.4rem;
      font-size: 1rem;
      display: flex;
      align-items: center;
      justify-content: center;
      transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1);
      
      &:hover {
        color: var(--primary-neon);
        transform: scale(1.2) rotate(90deg);
      }
      
      &:active {
        transform: scale(0.9) rotate(90deg);
      }
    }
  }

  .nav-channel-count {
    padding: 0.3rem 1.2rem 0.4rem;
    font-size: 0.7rem;
    color: var(--text-tertiary);
    letter-spacing: 0.03em;
    font-weight: 500;
  }

  .nav-no-results {
    padding: 2rem 1.2rem;
    font-size: 0.85rem;
    color: var(--text-tertiary);
    text-align: center;
  }

  .nav-loading {
    padding: 0.5rem 1.2rem;
    display: flex;
    flex-direction: column;
    gap: 0.6rem;
  }

  .skeleton {
    display: flex;
    align-items: center;
    gap: 0.8rem;
    padding: 0.5rem 0;
  }

  .skeleton-logo {
    width: 2.2rem;
    height: 1.4rem;
    border-radius: 4px;
    background: var(--border-light);
    animation: pulse 1.5s ease-in-out infinite;
    flex-shrink: 0;
  }

  .skeleton-line {
    height: 0.85rem;
    border-radius: 4px;
    background: var(--border-light);
    animation: pulse 1.5s ease-in-out infinite;
    flex: 1;
  }

  @keyframes pulse {
    0%, 100% { opacity: 0.3; }
    50% { opacity: 0.7; }
  }

  .active {
    color: var(--primary-neon);
    font-weight: 600;
  }

  .nav-list {
    margin: 0;
    padding: 0;
    list-style: none;
    flex: 1;
    overflow-y: auto;
    overflow-x: hidden;
    scrollbar-width: thin;
    scrollbar-color: var(--border-color) transparent;
    
    &::-webkit-scrollbar {
      width: 6px;
    }
    
    &::-webkit-scrollbar-track {
      background: transparent;
    }
    
    &::-webkit-scrollbar-thumb {
      background: var(--border-color);
      border-radius: 3px;
      
      &:hover {
        background: var(--primary-neon);
      }
    }
  }

  .sub-nav {
    padding: 0 1rem 0 1.2rem;
    height: 2.3rem;
    line-height: 2.3rem;
    display: flex;
    align-items: center;
    min-width: 0;
    transition: all 0.2s;
    
    &:hover {
      background: rgba(0, 217, 255, 0.08);
      padding-left: 1.4rem;
    }
    
    .tv-logo {
      max-width: 2.5rem;
      max-height: 1.6rem;
      margin-right: 0.8rem;
      border-radius: 4px;
      flex-shrink: 0;
      border: 1px solid var(--border-light);
    }
    
    a {
      white-space: nowrap;
      overflow: hidden;
      text-overflow: ellipsis;
      font-size: 0.88rem;
      min-width: 0;
      transition: color 0.2s;
      
      &:hover {
        color: var(--primary-neon);
      }
    }
  }

  .group-label {
    font-size: 0.7rem;
    font-weight: 700;
    text-transform: uppercase;
    letter-spacing: 0.1em;
    color: var(--text-tertiary);
    padding-top: 0.6rem;
  }

  a {
    color: var(--text-primary);
    text-decoration: none;
  }
}

@media (max-width: 600px) {
  .nav .nav-list-warp {
    width: 100vw;
  }
}
</style>
