<template>
  <div class="task-path-button-wrapper">
    <button 
      v-if="path" 
      class="button icon-button" 
      :class="workspaceStatus ? 'is-linked-btn' : 'is-unlinked-btn'"
      :title="workspaceStatus ? 'Unlink Workspace' : 'Link Workspace'" 
      @click.stop="toggleWorkspaceLink"
    >
      <UnlinkIcon v-if="workspaceStatus" class="icon is-small" size="16" />
      <LinkIcon v-else class="icon is-small" size="16" />
    </button>
    
    <button
      class="button icon-button"
      :class="{ 'is-loading': loading }"
      :title="path ? 'Open Folder' : 'Create Folder'"
      @click.stop="handleClick"
      :disabled="loading || (!!path && !workspaceStatus)"
    >
      <FolderOpenIcon v-if="path" class="icon is-small" size="16" />
      <FolderPlusIcon v-else class="icon is-small" size="16" />
    </button>
    
    <template v-if="path">
      <button class="button icon-button" title="Snapshots" @click.stop="showSnapshotsModal = true" :disabled="!workspaceStatus">
        <DatabaseIcon class="icon is-small" size="16" />
      </button>
      <button class="button icon-button" title="Create Snapshot" @click.stop="showCreateSnapshotModal = true" :disabled="!workspaceStatus">
        <CopyPlusIcon class="icon is-small" size="16" />
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
import { RefreshCwIcon, UnlinkIcon, LinkIcon, FolderOpenIcon, FolderPlusIcon, DatabaseIcon, CopyPlusIcon } from 'lucide-vue-next'

export default {
  name: 'task-path-button',
  components: {
    SnapshotsModal,
    CreateSnapshotModal,
    RefreshCwIcon,
    UnlinkIcon,
    LinkIcon,
    FolderOpenIcon,
    FolderPlusIcon,
    DatabaseIcon,
    CopyPlusIcon
  },
  props: {
    taskId: {
      type: String,
      required: true
    },
    assetType: {
      type: String,
      required: false,
      default: ''
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
    // computed properties removed since buttonText is no longer needed
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
        if (window.electronAPI && window.electronAPI.getTask) {
          const response = await window.electronAPI.getTask(id)
          if (response.success && response.data) {
            this.path = response.data.path || ''
          } else {
            this.path = ''
          }
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
        if (window.electronAPI && window.electronAPI.createAsset) {
          const response = await window.electronAPI.createAsset({ 
            id: this.taskId,
            assetType: this.assetType
          })
          
          if (response.success && response.data) {
            // The API returns the wekitsu_tasks record which has `path`
            if (response.data.path) {
              this.path = response.data.path
            } else {
              // Fallback in case path isn't directly on data, fetch it
              await this.fetchPath(this.taskId)
            }
          } else {
            console.error('Failed to create task folder')
          }
        } else {
           console.error('Failed to create task folder: electronAPI not available')
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
    async toggleWorkspaceLink() {
      if (!this.path || !window.electronAPI) return;
      
      this.loading = true;
      try {
        if (this.workspaceStatus) {
          if (window.electronAPI.unlinkFromWorkspace) {
            const res = await window.electronAPI.unlinkFromWorkspace(this.taskId, this.path);
            if (!res.success) {
              if (!res.cancelled && res.error) {
                alert(`Failed to unlink workspace:\n${res.error}`);
              }
              return; // Do not update status
            }
          }
        } else {
          if (window.electronAPI.linkToWorkspace) {
            const res = await window.electronAPI.linkToWorkspace(this.taskId, this.path);
            if (!res.success) {
              if (!res.cancelled && res.error) {
                alert(`Failed to link workspace:\n${res.error}`);
              }
              return; // Do not update status
            }
          }
        }
        
        if (window.electronAPI.checkWorkspacePath) {
          this.workspaceStatus = await window.electronAPI.checkWorkspacePath(this.path);
        }
      } catch (err) {
        console.error('Failed to toggle workspace link:', err);
      } finally {
        this.loading = false;
      }
    }
  }
}
</script>

<style scoped>
.wekitsu-path {
  font-family: monospace;
  font-size: 0.9em;
}

.is-linked-btn {
  background-color: #48c774 !important;
  color: white !important;
  border-color: transparent !important;
}

.is-unlinked-btn {
  background-color: #dbdbdb !important;
  color: #363636 !important;
  border-color: transparent !important;
}
.task-path-button-wrapper {
  position: relative;
  display: flex;
  align-items: center;
  gap: 0.25rem;
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
