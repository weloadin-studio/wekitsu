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
import ModalFooter from '@/components/modals/ModalFooter.vue'

export default {
  name: 'edit-default-comment-modal',

  mixins: [modalMixin],

  components: {
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
        comment: ''
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
    confirmClicked() {
      if (!this.form.assetTypeId || !this.form.taskTypeId || !this.form.comment) {
         return; // Simple validation
      }
      this.$emit('confirm', { ...this.form })
    }
  },

  watch: {
    active() {
      if (this.commentToEdit && this.commentToEdit.id) {
        this.form = {
          id: this.commentToEdit.id,
          assetTypeId: this.commentToEdit.assetTypeId,
          taskTypeId: this.commentToEdit.taskTypeId,
          comment: this.commentToEdit.comment
        }
      } else {
        this.form = {
          assetTypeId: '',
          taskTypeId: '',
          comment: ''
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
