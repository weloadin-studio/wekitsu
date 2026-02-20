<template>
  <div class="task-path-button-wrapper">
    <button
      class="button"
      :class="{ 'is-loading': loading }"
      @click.stop="handleClick"
      :disabled="loading"
    >
      {{ buttonText }}
    </button>
    
    <template v-if="path">
      <button class="button ml-1 icon-button" title="Workspace Status" @click.stop="syncWorkspace">
        <RefreshCwIcon v-if="workspaceStatus" class="icon is-small" size="16" />
        <UnlinkIcon v-else class="icon is-small" size="16" />
      </button>
      <button class="button ml-1" @click.stop="showSnapshotsModal = true">
        {{ $t('task_path.snapshots', 'Snapshots') }}
      </button>
      <button class="button ml-1" @click.stop="showCreateSnapshotModal = true">
        {{ $t('task_path.create_snapshot', 'Create Snapshot') }}
      </button>
    </template>

    <transition name="fade">
      <div v-if="showToast" class="toast-popup">Path copied!</div>
    </transition>

    <snapshots-modal
      :active="showSnapshotsModal"
      :taskId="taskId"
      @cancel="showSnapshotsModal = false"
    />

    <create-snapshot-modal
      :active="showCreateSnapshotModal"
      :taskId="taskId"
      @cancel="showCreateSnapshotModal = false"
      @confirm="onSnapshotCreated"
    />
  </div>
</template>

<script>
import SnapshotsModal from '@/components/modals/SnapshotsModal.vue'
import CreateSnapshotModal from '@/components/modals/CreateSnapshotModal.vue'
import { RefreshCwIcon, UnlinkIcon } from 'lucide-vue-next'

export default {
  name: 'task-path-button',
  components: {
    SnapshotsModal,
    CreateSnapshotModal,
    RefreshCwIcon,
    UnlinkIcon
  },
  props: {
    taskId: {
      type: String,
      required: true
    }
  },
  data() {
    return {
      path: '',
      loading: false,
      showToast: false,
      showSnapshotsModal: false,
      showCreateSnapshotModal: false,
      workspaceStatus: false
    }
  },
  computed: {
    buttonText() {
      if (this.loading) return 'Loading...'
      return this.path || 'Create Folder'
    }
  },
  watch: {
    taskId: {
      immediate: true,
      handler(newId) {
        if (newId) {
          this.fetchPath(newId)
        }
      }
    },
    path: {
      immediate: true,
      async handler(newPath) {
        if (newPath && window.electronAPI && window.electronAPI.checkWorkspacePath) {
          try {
            this.workspaceStatus = await window.electronAPI.checkWorkspacePath(newPath)
          } catch (err) {
            console.error('Failed to check workspace path:', err)
            this.workspaceStatus = false
          }
        } else {
          this.workspaceStatus = false
        }
      }
    }
  },
  methods: {
    async fetchPath(id) {
      if (!id) return
      this.loading = true
      try {
        const response = await fetch(`/wekitsu-api/get-task/${id}`)
        if (response.ok) {
          const data = await response.json()
          this.path = data.path || ''
        } else {
          this.path = ''
        }
      } catch (e) {
        console.error(e)
        this.path = ''
      } finally {
        this.loading = false
      }
    },
    async handleClick() {
      if (this.path) {
        try {
          if (window.electronAPI) {
            window.electronAPI.openExplorer(this.path)
          } else {
            await navigator.clipboard.writeText(this.path)
          }

          this.showToast = true
          setTimeout(() => {
            this.showToast = false
          }, 2000)
        } catch (err) {
          console.error('Failed to copy text: ', err)
        }
        return
      }

      this.loading = true
      try {
        const response = await fetch(
          '/wekitsu-api/create-task-folder',
          {
            method: 'POST',
            headers: {
              'Content-Type': 'application/json'
            },
            body: JSON.stringify({ id: this.taskId })
          }
        )

        if (response.ok) {
          const data = await response.json()
          if (data && data.path) {
            this.path = data.path
          }
        } else {
          console.error('Failed to create task folder')
        }
      } catch (e) {
        console.error('Error creating task folder:', e)
      } finally {
        this.loading = false
      }
    },
    onSnapshotCreated() {
      this.showCreateSnapshotModal = false
      // Optionally open the snapshots list to show the new one
      this.showSnapshotsModal = true
    },
    async syncWorkspace() {
      if (this.path && window.electronAPI && window.electronAPI.syncFromServer) {
        try {
          await window.electronAPI.syncFromServer(this.path)
        } catch (err) {
          console.error('Failed to sync from server:', err)
        }
      }
    }
  }
}
</script>

<style scoped>
.task-path-button-wrapper {
  position: relative;
  display: inline-block;
}

.button.ml-1 {
  margin-left: 0.5rem;
}

.icon-button {
  padding: 0 0.5rem;
  display: inline-flex;
  align-items: center;
  justify-content: center;
}

.toast-popup {
  position: absolute;
  top: -35px;
  left: 50%;
  transform: translateX(-50%);
  background-color: #333;
  color: #fff;
  padding: 5px 10px;
  border-radius: 4px;
  font-size: 12px;
  white-space: nowrap;
  pointer-events: none;
  opacity: 0.9;
  z-index: 1000;
}

.toast-popup::after {
  content: '';
  position: absolute;
  top: 100%;
  left: 50%;
  margin-left: -5px;
  border-width: 5px;
  border-style: solid;
  border-color: #333 transparent transparent transparent;
}

.fade-enter-active,
.fade-leave-active {
  transition: opacity 0.3s;
}

.fade-enter-from,
.fade-leave-to {
  opacity: 0;
}
</style>
