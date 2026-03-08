<template>
  <div class="default-comments page fixed-page">
    <list-page-header
      title="Default Comments"
      new-entry-label="New Default Comment"
      :is-exportable="false"
      @new-clicked="onNewClicked"
    />

    <div class="table-body mt2">
      <table class="datatable mx-auto max-width-1000">
        <thead>
          <tr>
            <th>Production</th>
            <th>Asset Type</th>
            <th>Task Type</th>
            <th>Comment</th>
            <th>Actions</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="dc in displayedDefaultComments" :key="dc.id">
            <td>{{ getProductionName(dc.productionId) }}</td>
            <td>{{ getAssetTypeName(dc.assetTypeId) }}</td>
            <td>{{ getTaskTypeName(dc.taskTypeId) }}</td>
            <td>{{ dc.comment }}</td>
            <td>
              <div class="flexrow">
                <button class="button flexrow-item" @click="startEdit(dc)" title="Edit">
                  <edit-2-icon class="icon" />
                </button>
                <button class="button is-danger flexrow-item" @click="deleteComment(dc.id)" title="Delete">
                  <trash-2-icon class="icon" />
                </button>
              </div>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
    
    <edit-default-comment-modal
      :active="isModalActive"
      :comment-to-edit="selectedComment"
      :productions="openProductions"
      :current-production-id="currentProduction ? currentProduction.id : ''"
      :is-loading="isSaving"
      :is-error="modalError"
      @cancel="closeModal"
      @confirm="saveComment"
    />
  </div>
</template>

<script>
import { mapGetters, mapActions } from 'vuex'
import { Edit2Icon, Trash2Icon } from 'lucide-vue-next'
import ListPageHeader from '@/components/widgets/ListPageHeader.vue'
import EditDefaultCommentModal from '@/components/modals/EditDefaultCommentModal.vue'

export default {
  name: 'default-comments',

  components: {
    ListPageHeader,
    Edit2Icon,
    Trash2Icon,
    EditDefaultCommentModal
  },

  data() {
    return {
      defaultComments: [],
      isModalActive: false,
      isSaving: false,
      modalError: false,
      selectedComment: null
    }
  },

  computed: {
    ...mapGetters(['assetTypes', 'taskTypes', 'openProductions', 'currentProduction']),
    
    assetTypeMap() {
        return new Map(this.assetTypes.map(at => [at.id, at.name]));
    },
    
    taskTypeMap() {
        return new Map(this.taskTypes.map(tt => [tt.id, tt.name]));
    },

    productionMap() {
        return new Map(this.openProductions.map(p => [p.id, p.name]));
    },

    displayedDefaultComments() {
        return this.defaultComments;
    }
  },

  async mounted() {
    await Promise.all([
      this.loadAssetTypes(),
      this.loadTaskTypes()
    ]);
    this.fetchDefaultComments()
  },

  methods: {
    ...mapActions(['loadAssetTypes', 'loadTaskTypes']),

    getProductionName(id) {
        return this.productionMap.get(id) || 'Unknown Production';
    },

    getAssetTypeName(id) {
        return this.assetTypeMap.get(id) || 'Unknown Asset Type';
    },

    getTaskTypeName(id) {
        return this.taskTypeMap.get(id) || 'Unknown Task Type';
    },

    async fetchDefaultComments() {
      try {
        const response = await window.electronAPI.getDefaultComments();
        if (response.success) {
           this.defaultComments = response.data;
        } else {
           console.error('Failed to fetch default comments:', response.error);
        }
      } catch (err) {
        console.error('API Error: ', err)
      }
    },

    onNewClicked() {
      this.selectedComment = null
      this.isModalActive = true
      this.modalError = false
    },
    
    closeModal() {
      this.isModalActive = false
    },

    startEdit(commentRow) {
      this.selectedComment = commentRow
      this.isModalActive = true
      this.modalError = false
    },

    async saveComment(form) {
      this.isSaving = true
      this.modalError = false
      try {
        let response
        if (form.id) {
           response = await window.electronAPI.updateDefaultComment(form.id, form.comment);
        } else {
           // Provide fallback to current production id just in case modal forgot it
           if (!form.productionId && this.currentProduction) {
              form.productionId = this.currentProduction.id;
           }
           response = await window.electronAPI.createDefaultComment({ ...form });
        }
        
        if (response.success) {
           this.isModalActive = false;
           await this.fetchDefaultComments();
        } else {
           console.error('Failed to save default comment:', response.error);
           this.modalError = true;
        }
      } catch (err) {
        console.error('API save error:', err)
        this.modalError = true;
      } finally {
        this.isSaving = false;
      }
    },

    async deleteComment(id) {
       if (!confirm("Are you sure you want to delete this default comment?")) return;
       try {
        const response = await window.electronAPI.deleteDefaultComment(id);
        if (response.success) {
           await this.fetchDefaultComments();
        }
       } catch (err) {
           console.error('Update err: ', err)
       }
    }
  }
}
</script>

<style lang="scss" scoped>
.max-width-1000 {
  max-width: 1000px;
}
.icon {
  width: 16px;
  height: 16px;
}
.input {
  width: 100%;
  padding: 8px;
  border: 1px solid var(--border);
  border-radius: 4px;
  background: var(--background);
  color: var(--text);
}
</style>
