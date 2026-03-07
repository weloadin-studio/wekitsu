<template>
  <div :class="{ modal: true, 'is-active': active }">
    <div class="modal-background" @click="$emit('cancel')"></div>
    <div class="modal-content">
      <div class="box content">
        <div class="columns is-vcentered mb-4">
          <div class="column">
            <h3 class="title">
              {{ $t('main.linked_tasks', 'Linked Tasks') }}
            </h3>
          </div>
          <div class="column is-narrow has-text-right">
            <button class="button is-danger" @click="confirmBulkUnlink" :disabled="isLoading || selectedTasks.length === 0">
              Unlink Selected ({{ selectedTasks.length }})
            </button>
          </div>
        </div>

        <div class="datatable-wrapper">
          <table class="datatable is-fullwidth">
            <thead class="datatable-head">
              <tr>
                <th class="datatable-row-header" style="width: 40px; text-align: center;">
                  <input type="checkbox" :checked="isAllSelected" @change="toggleAllSelection" />
                </th>
                <th class="datatable-row-header">Asset</th>
                <th class="datatable-row-header">Task</th>
                <th class="datatable-row-header">Local Path</th>
                <th class="datatable-row-header">Status</th>
                <th class="datatable-row-header action">Actions</th>
              </tr>
            </thead>
            <tbody class="datatable-body">
              <tr v-for="task in displayTasks" :key="task.id" class="datatable-row">
                <td style="text-align: center;">
                  <input type="checkbox" :value="task.id" v-model="selectedTasks" />
                </td>
                <td>
                  <router-link :to="getAssetRoute(task)" @click="$emit('cancel')">
                    {{ task.entity_name }}
                  </router-link>
                </td>
                <td>{{ task.name }}</td>
                <td>{{ task.localPath }}</td>
                <td>
                  <span class="tag is-success">Linked</span>
                </td>
                <td class="action flexrow" style="justify-content: center; gap: 0.5rem">
                  <button class="button icon-button" title="Open Folder" @click="openFolder(task.localPath)">
                    <icon-folder-open class="icon is-small" size="16" />
                  </button>
                  <button class="button icon-button is-danger" title="Unlink" @click="confirmUnlink(task)">
                    <icon-unlink class="icon is-small" size="16" />
                  </button>
                </td>
              </tr>
              <tr v-if="isLoading">
                <td colspan="6" class="has-text-centered">
                  {{ $t('main.loading', 'Loading...') }}
                </td>
              </tr>
              <tr v-if="!isLoading && displayTasks.length === 0">
                <td colspan="6" class="has-text-centered">
                  No linked tasks found.
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
    
    <confirm-modal
      :active="showConfirm"
      :text="confirmText"
      :confirmButtonText="confirmButtonText"
      :isLoading="isActionLoading"
      @cancel="cancelAction"
      @confirm="performAction"
    />
  </div>
</template>

<script>
import { modalMixin } from '@/components/modals/base_modal'
import ConfirmModal from '@/components/modals/ConfirmModal.vue'
import { Unlink as IconUnlink, FolderOpen as IconFolderOpen } from 'lucide-vue-next'

export default {
  name: 'linked-tasks-modal',
  mixins: [modalMixin],
  components: {
    ConfirmModal,
    IconUnlink,
    IconFolderOpen
  },
  props: {
    active: {
      type: Boolean,
      default: false
    }
  },
  emits: ['cancel'],
  data() {
    return {
      tasks: [],
      selectedTasks: [],
      isLoading: false,
      
      showConfirm: false,
      confirmText: '',
      confirmButtonText: '',
      isActionLoading: false,
      pendingAction: null
    }
  },
  computed: {
    displayTasks() {
      return this.tasks;
    },
    isAllSelected() {
      return this.tasks.length > 0 && this.selectedTasks.length === this.tasks.length;
    }
  },
  methods: {
    toggleAllSelection(event) {
      if (event.target.checked) {
        this.selectedTasks = this.tasks.map(t => t.id);
      } else {
        this.selectedTasks = [];
      }
    },
    
    getAssetRoute(task) {
      if (!task || !task.project_id || !task.entity_id) return '';
      return `/productions/${task.project_id}/assets/${task.entity_id}`;
    },

    openFolder(path) {
      if (window.electronAPI && window.electronAPI.openExplorer) {
        window.electronAPI.openExplorer(path);
      }
    },

    async loadTasks() {
      if (!window.electronAPI || !window.electronAPI.getLinkedWorkspaceTasks) return;
      this.isLoading = true;
      try {
        const linkedMap = await window.electronAPI.getLinkedWorkspaceTasks();
        const taskIds = Object.keys(linkedMap);
        
        let loadedTasks = [];
        for (const taskId of taskIds) {
          try {
            const res = await window.electronAPI.getTask(taskId);
            if (res && res.success && res.data) {
                loadedTasks.push({
                   id: taskId,
                   name: res.data.taskType || res.data.name || 'Unknown Task',
                   entity_name: res.data.assetName || 'Unknown Entity',
                   project_id: res.data.projectId,
                   entity_id: res.data.entityId,
                   localPath: linkedMap[taskId],
                   ...res.data
                });
            } else {
                loadedTasks.push({
                   id: taskId,
                   name: 'Unknown',
                   entity_name: 'Deleted / Not Found',
                   localPath: linkedMap[taskId]
                });
            }
          } catch(e) {
             loadedTasks.push({
               id: taskId,
               name: 'Unknown',
               entity_name: 'Error Fetching',
               localPath: linkedMap[taskId]
             });
          }
        }
        this.tasks = loadedTasks;
      } catch (e) {
        console.error("Failed to load linked tasks", e);
      } finally {
        this.isLoading = false;
      }
    },

    confirmUnlink(task) {
      this.pendingAction = { type: 'single', task }
      this.confirmText = `Are you sure you want to unlink and delete the local workspace folder for this task? (${task.localPath})`
      this.confirmButtonText = 'Unlink'
      this.showConfirm = true
    },

    confirmBulkUnlink() {
      if (this.selectedTasks.length === 0) return;
      this.pendingAction = { type: 'bulk' }
      this.confirmText = `Are you sure you want to unlink the ${this.selectedTasks.length} selected tasks and delete their local workspace folders?`
      this.confirmButtonText = 'Unlink Selected'
      this.showConfirm = true
    },

    cancelAction() {
      this.showConfirm = false
      this.pendingAction = null
      this.isActionLoading = false
    },

    async performAction() {
      if (!this.pendingAction) return;
      this.isActionLoading = true;
      
      try {
        if (this.pendingAction.type === 'single') {
           const { task } = this.pendingAction;
           await window.electronAPI.unlinkFromWorkspace(task.id, task.localPath);
        } else if (this.pendingAction.type === 'bulk') {
           const tasksToUnlink = this.tasks.filter(t => this.selectedTasks.includes(t.id));
           for (const task of tasksToUnlink) {
              await window.electronAPI.unlinkFromWorkspace(task.id, task.localPath);
           }
        }
        this.showConfirm = false;
        this.pendingAction = null;
        this.selectedTasks = []; // clear selection after deletion
        await this.loadTasks(); // refresh
      } catch (e) {
        console.error("Failed to unlink", e);
      } finally {
        this.isActionLoading = false;
      }
    }
  },
  watch: {
    active(newVal) {
      if (newVal) {
        this.tasks = [];
        this.selectedTasks = [];
        this.loadTasks();
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
  border: 0px solid #dbdbdb;
  border-radius: 4px;
}
.datatable {
  margin-bottom: 0;
}
.datatable-head th {
  position: sticky;
  top: 0;
  background: rgb(73, 73, 73); 
  z-index: 10;
  box-shadow: 0 0px 0 #1b1b1b;
}
:global(.dark) .datatable-head th {
  background: #2f3136; 
  color: #444444;
  box-shadow: 0 0px 0 #1b1b1b;
}
.action {
  width: 100px;
  text-align: center;
}
.modal-footer {
  border-top: 0px solid #dbdbdb;
  padding-top: 1rem;
}
:global(.dark) .modal-footer {
  border-top-color: #40444b;
}
.icon-button {
  padding: 0 0.5rem;
  display: inline-flex;
  align-items: center;
  justify-content: center;
}
</style>
