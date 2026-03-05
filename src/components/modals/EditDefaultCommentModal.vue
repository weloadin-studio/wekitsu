<template>
  <div
    :class="{
      modal: true,
      'is-active': active
    }"
  >
    <div class="modal-background" @click="$emit('cancel')"></div>

    <div class="modal-content">
      <div class="box">
        <h1 class="title" v-if="isEditing">
          Edit Default Comment
        </h1>
        <h1 class="title" v-else>
          New Default Comment
        </h1>

        <form @submit.prevent>
          <div class="field">
             <label class="label">Asset Type</label>
             <div class="control">
               <div class="select is-fullwidth">
                 <select v-model="form.assetTypeId" :disabled="isEditing">
                   <option disabled value="">Select Asset Type...</option>
                   <option v-for="at in assetTypes" :key="at.id" :value="at.id">{{ at.name }}</option>
                 </select>
               </div>
             </div>
          </div>

          <div class="field">
             <label class="label">Task Type</label>
             <div class="control">
               <div class="select is-fullwidth">
                 <select v-model="form.taskTypeId" :disabled="isEditing">
                   <option disabled value="">Select Task Type...</option>
                   <option v-for="tt in taskTypes" :key="tt.id" :value="tt.id">{{ tt.name }}</option>
                 </select>
               </div>
             </div>
          </div>
          
          <div class="field">
             <label class="label">Default Comment</label>
             <div class="control">
               <input class="input" type="text" v-model="form.comment" @keyup.enter="confirmClicked" placeholder="Your default comment..." />
             </div>
          </div>
          <div class="field">
             <div class="control">
                <div class="post-area">
                  <checklist
                      :checklist="form.checklist"
                      @add-item="onAddChecklistItem"
                      @insert-item="onInsertChecklistItem"
                      @remove-task="removeTask"
                      v-if="form.checklist && form.checklist.length > 0"
                  />
                  <div class="flexrow button-row mt1">
                    <button-simple
                        :class="{
                          'flexrow-item': true,
                          active: form.checklist && form.checklist.length !== 0
                        }"
                        icon="list"
                        title="Add Checklist"
                        @click="addChecklistEntry(-1)"
                    />
                  </div>
                </div>
             </div>
          </div>
        </form>

        <modal-footer
          :error-text="errorText"
          :is-loading="isLoading"
          :is-error="isError"
          @confirm="confirmClicked"
          @cancel="$emit('cancel')"
        />
      </div>
    </div>
  </div>
</template>

<script>
import { mapGetters } from 'vuex'
import { modalMixin } from '@/components/modals/base_modal'
import Checklist from '@/components/widgets/Checklist.vue'
import ButtonSimple from '@/components/widgets/ButtonSimple.vue'
import ModalFooter from '@/components/modals/ModalFooter.vue'

export default {
  name: 'edit-default-comment-modal',

  mixins: [modalMixin],

  components: {
    Checklist,
    ButtonSimple,
    ModalFooter
  },

  props: {
    active: {
      type: Boolean,
      default: false
    },
    isError: {
      type: Boolean,
      default: false
    },
    isLoading: {
      type: Boolean,
      default: false
    },
    commentToEdit: {
      type: Object,
      default: () => null
    }
  },

  emits: ['cancel', 'confirm'],

  data() {
    return {
      form: {
        assetTypeId: '',
        taskTypeId: '',
        comment: '',
        checklist: []
      }
    }
  },

  computed: {
    ...mapGetters(['assetTypes', 'taskTypes']),
    isEditing() {
      return this.commentToEdit && this.commentToEdit.id
    },
    errorText() {
        return this.isEditing ? 'Failed to update comment' : 'Failed to create comment'
    }
  },

  methods: {
    addChecklistEntry(index) {
        if (!this.form.checklist) this.form.checklist = []
        this.onAddChecklistItem({
            index: index,
            text: '',
            frame: -1,
            revision: -1,
            checked: false
        })
    },
    
    onAddChecklistItem(item) {
        if (!this.form.checklist) this.form.checklist = []
        delete item.index
        this.form.checklist.push(item)
    },
    
    onInsertChecklistItem(item) {
        if (!this.form.checklist) this.form.checklist = []
        this.form.checklist.splice(item.index, 0, item)
        for (let i = 0; i < this.form.checklist.length; i++) {
           this.form.checklist[i].index = i
        }
    },
    
    removeTask(item) {
        this.form.checklist = this.form.checklist.filter(entry => entry !== item)
    },

    confirmClicked() {
      if (!this.form.assetTypeId || !this.form.taskTypeId || !this.form.comment) {
         return; // Simple validation
      }
      
      let payload = { ...this.form };
      if (payload.checklist) {
          payload.checklist = payload.checklist.filter(item => item.text && item.text.trim().length > 0)
      }
      
      // Strip Vue reactive proxies to prevent structuredClone errors over IPC
      payload = JSON.parse(JSON.stringify(payload))
      
      this.$emit('confirm', payload)
    }
  },

  watch: {
    active() {
      if (this.commentToEdit && this.commentToEdit.id) {
        this.form = {
          id: this.commentToEdit.id,
          assetTypeId: this.commentToEdit.assetTypeId,
          taskTypeId: this.commentToEdit.taskTypeId,
          comment: this.commentToEdit.comment,
          checklist: this.commentToEdit.checklist ? JSON.parse(JSON.stringify(this.commentToEdit.checklist)) : []
        }
      } else {
        this.form = {
          assetTypeId: '',
          taskTypeId: '',
          comment: '',
          checklist: []
        }
      }
    }
  }
}
</script>

<style lang="scss" scoped>
.modal-content .box p.text {
  margin-bottom: 1em;
}
</style>
