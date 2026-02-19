<template>
  <div
    :class="{
      modal: true,
      'is-active': active
    }"
  >
    <div class="modal-background" @click="$emit('cancel')"></div>

    <div class="modal-content">
      <div class="box content">
        <h1 class="title">
          {{ $t('snapshots.title', 'Snapshots') }}
        </h1>

        <div class="table-container">
          <table class="table is-fullwidth">
            <thead>
              <tr>
                <th class="thumbnail">{{ $t('snapshots.thumbnail', 'Thumbnail') }}</th>
                <th class="date">{{ $t('snapshots.created_at', 'Created At') }}</th>
                <th class="type">{{ $t('snapshots.type', 'Type') }}</th>
                <th class="message">{{ $t('snapshots.message', 'Message') }}</th>
                <th class="action">{{ $t('snapshots.download', 'Download') }}</th>
              </tr>
            </thead>
            <tbody ref="scrollBody" @scroll="onScroll" class="scroll-body">
              <tr v-for="snapshot in snapshots" :key="snapshot.commitId">
                <td class="thumbnail">
                  <img
                    v-if="snapshot.thumbnailUrl"
                    :src="snapshot.thumbnailUrl"
                    alt="Thumbnail"
                    class="snapshot-thumb"
                  />
                  <div v-else class="placeholder-thumb">
                    <icon-image />
                  </div>
                </td>
                <td class="date">
                  {{ formatDate(snapshot.createdAt) }}
                </td>
                <td class="type">
                  <span class="tag">{{ snapshot.type }}</span>
                </td>
                <td class="message">
                  {{ snapshot.message }}
                </td>
                <td class="action">
                  <a
                    v-if="snapshot.zipUrl"
                    :href="snapshot.zipUrl"
                    class="button is-small is-primary"
                    target="_blank"
                    download
                  >
                    <icon-download />
                  </a>
                </td>
              </tr>
              <tr v-if="isLoading">
                <td colspan="5" class="has-text-centered">
                  {{ $t('main.loading', 'Loading...') }}
                </td>
              </tr>
              <tr v-if="!isLoading && snapshots.length === 0">
                <td colspan="5" class="has-text-centered">
                  {{ $t('snapshots.no_snapshots', 'No snapshots found.') }}
                </td>
              </tr>
            </tbody>
          </table>
        </div>

        <div class="has-text-right modal-footer">
          <button @click="$emit('cancel')" class="button">
            {{ $t('main.close', 'Close') }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { modalMixin } from '@/components/modals/base_modal'
import { formatDate } from '@/lib/time'
import { Download as IconDownload, Image as IconImage } from 'lucide-vue-next'

export default {
  name: 'snapshots-modal',

  mixins: [modalMixin],

  components: {
    IconDownload,
    IconImage
  },

  props: {
    active: {
      type: Boolean,
      default: false
    },
    taskId: {
      type: String,
      required: true
    }
  },

  emits: ['cancel'],

  data() {
    return {
      snapshots: [],
      isLoading: false,
      isError: false,
      page: 1,
      hasMore: true
    }
  },

  methods: {
    formatDate(dateString) {
      return formatDate(dateString)
    },

    async loadSnapshots(reset = false) {
      if (this.isLoading || (!this.hasMore && !reset)) return
      
      if (reset) {
        this.page = 1
        this.snapshots = []
        this.hasMore = true
      }

      this.isLoading = true
      this.isError = false

      try {
        const response = await fetch(
          `/wekitsu-api/snapshots/${this.taskId}?page=${this.page}&limit=20`
        )
        if (response.ok) {
          const data = await response.json()
          if (data && Array.isArray(data)) {
            if (data.length < 20) {
              this.hasMore = false
            }
            this.snapshots = [...this.snapshots, ...data]
            this.page++
          } else {
            this.hasMore = false
          }
        } else {
          this.isError = true
          console.error('Failed to load snapshots')
        }
      } catch (e) {
        console.error('Error loading snapshots:', e)
        this.isError = true
      } finally {
        this.isLoading = false
      }
    },

    onScroll(e) {
      const { scrollTop, clientHeight, scrollHeight } = e.target
      if (scrollHeight - scrollTop <= clientHeight + 50) {
        this.loadSnapshots()
      }
    },

    reset() {
      this.snapshots = []
      this.page = 1
      this.hasMore = true
      this.isLoading = false
      this.isError = false
    }
  },

  watch: {
    active(newVal) {
      if (newVal) {
        this.reset()
        this.loadSnapshots(true)
      }
    }
  }
}
</script>

<style lang="scss" scoped>
.modal-content {
  width: 960px;
  max-width: 90vw;
}

.table-container {
  max-height: 60vh;
  overflow-y: hidden; /* Scroll happen in tbody */
  display: flex;
  flex-direction: column;
}

table {
  display: flex;
  flex-direction: column;
  height: 100%;
}

thead {
  flex: 0 0 auto;
}

tbody.scroll-body {
  flex: 1 1 auto;
  display: block;
  overflow-y: auto;
  max-height: 50vh;
  width: 100%;
}

tr {
  display: table;
  width: 100%;
  table-layout: fixed;
}

.thumbnail {
  width: 80px;
  text-align: center;
}

.date {
  width: 150px;
}

.type {
  width: 100px;
}

.action {
  width: 100px;
  text-align: center;
}

.snapshot-thumb {
  max-width: 60px;
  max-height: 60px;
  border-radius: 4px;
}

.placeholder-thumb {
  width: 60px;
  height: 60px;
  background: #eee;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 4px;
  color: #aaa;
}
</style>
