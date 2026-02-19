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
        <div class="columns is-vcentered mb-4">
          <div class="column">
            <h3 class="title is-4">
              {{ $t('snapshots.title', 'Snapshots') }}
            </h3>
          </div>
          <div class="column is-narrow">
            <div class="select">
              <select v-model="filterType">
                <option value="all">{{ $t('main.all', 'All') }}</option>
                <option value="source">Source</option>
                <option value="export">Exports</option>
              </select>
            </div>
          </div>
        </div>

        <div class="datatable-wrapper" ref="scrollBody">
          <table class="datatable is-fullwidth">
            <thead class="datatable-head">
              <tr>
                <th class="thumbnail datatable-row-header">{{ $t('snapshots.thumbnail', 'Thumbnail') }}</th>
                <th class="date datatable-row-header">{{ $t('snapshots.created_at', 'Created At') }}</th>
                <th class="type datatable-row-header">{{ $t('snapshots.type', 'Type') }}</th>
                <th class="message datatable-row-header">{{ $t('snapshots.message', 'Message') }}</th>
                <th class="action datatable-row-header">{{ $t('snapshots.download', 'Download') }}</th>
              </tr>
            </thead>
            <tbody class="datatable-body">
              <tr 
                v-for="snapshot in filteredSnapshots" 
                :key="snapshot.commitId"
                class="datatable-row"
              >
                <td class="thumbnail datatable-row-header">
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
                <td class="date datatable-row-header">
                  {{ formatDate(snapshot.createdAt) }}
                </td>
                <td class="type datatable-row-header">
                  <span class="tag">{{ snapshot.type }}</span>
                </td>
                <td class="message datatable-row-header">
                  {{ snapshot.message }}
                </td>
                <td class="action datatable-row-header">
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
              <tr v-if="!isLoading && filteredSnapshots.length === 0">
                <td colspan="5" class="has-text-centered">
                  {{ $t('snapshots.no_snapshots', 'No snapshots found.') }}
                </td>
              </tr>
            </tbody>
          </table>
        </div>

        <div class="has-text-right modal-footer mt-4">
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
      filterType: 'all'
    }
  },

  computed: {
    filteredSnapshots() {
      if (this.filterType === 'all') {
        return this.snapshots
      }
      // Handle "exports" needing to match singular "export" in data if inconsistent,
      // strictly user asked for "export" and "exports". API returns "exports" for type export
      // based on curl output: "type": "exports".
      // But user said: "when source is selected it, only the snapshots with type 'source' should show up, the same goes for 'exports'"
      // My dropdown has values: 'source', 'export'.
      // If API returns 'exports' (plural) and dropdown is 'export' (singular) or 'exports' (plural), need to match.
      // Easiest is to loosely match check.
      return this.snapshots.filter(s => {
          if (this.filterType === 'all') return true
          // If dropdown is 'export' and data is 'exports' or vice versa
          if (this.filterType === 'export' || this.filterType === 'exports') {
             return s.type === 'export' || s.type === 'exports'
          }
          return s.type === this.filterType
      })
    }
  },

  methods: {
    formatDate(dateString) {
      return formatDate(dateString)
    },

    async loadSnapshots() {
      this.isLoading = true
      this.isError = false
      this.snapshots = []

      // Client-side filtering only, load everything once.
      // API does not seem to support pagination either based on "forget about pagination"
      const url = `/wekitsu-api/snapshots/${this.taskId}`

      try {
        const response = await fetch(url)
        if (response.ok) {
          const data = await response.json()
          if (data && Array.isArray(data)) {
            this.snapshots = data
          }
        } else {
          // If 404, just empty list
          if (response.status !== 404) {
             console.error('Failed to load snapshots')
             this.isError = true
          }
        }
      } catch (e) {
        console.error('Error loading snapshots:', e)
        this.isError = true
      } finally {
        this.isLoading = false
      }
    },

    reset() {
      this.snapshots = []
      this.isLoading = false
      this.isError = false
      this.filterType = 'all'
    }
  },

  watch: {
    active(newVal) {
      if (newVal) {
        this.reset()
        this.loadSnapshots()
      }
    }
  }
}
</script>


<style lang="scss" scoped>
.modal-content {
  width: 80%;
  max-width: 80%;
}

.datatable-wrapper {
  max-height: 60vh;
  overflow-y: auto;
  border: 1px solid #dbdbdb;
  border-radius: 4px;
}

.datatable {
  margin-bottom: 0;
}

.datatable-head th {
  position: sticky;
  top: 0;
  background: white; /* Ensure header is opaque */
  z-index: 10;
  box-shadow: 0 1px 0 #dbdbdb;
}

/* Dark mode support for sticky header */
:global(.dark) .datatable-head th {
  background: #2f3136; /* Adjust based on your dark theme */
  color: #b9bbbe;
  box-shadow: 0 1px 0 #40444b;
}

.thumbnail {
  width: 80px;
  text-align: center;
}

.date {
  width: 180px;
}

.type {
  width: 120px;
}




.action {
  width: 100px;
  text-align: center;
}

.snapshot-thumb {
  max-width: 60px;
  max-height: 60px;
  border-radius: 4px;
  object-fit: cover;
}

.placeholder-thumb {
  width: 60px;
  height: 60px;
  background: #f5f5f5;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 4px;
  color: #ccc;
  margin: 0 auto;
}

:global(.dark) .placeholder-thumb {
  background: #40444b;
  color: #72767d;
}

.modal-footer {
  border-top: 1px solid #dbdbdb;
  padding-top: 1rem;
}

:global(.dark) .modal-footer {
  border-top-color: #40444b;
}

</style>
