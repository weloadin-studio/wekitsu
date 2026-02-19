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
        <h1 class="title">
          {{ $t('snapshots.create_title', 'Create Snapshot') }}
        </h1>

        <div class="field">
          <label class="label">{{ $t('snapshots.type', 'Type') }}</label>
          <div class="control">
            <div class="select is-fullwidth">
              <select v-model="form.type">
                <option value="source">Source</option>
                <option value="export">Export</option>
              </select>
            </div>
          </div>
        </div>

        <div class="field">
          <label class="label">{{ $t('snapshots.thumbnail', 'Thumbnail') }}</label>
          <file-upload
            ref="thumbnailUpload"
            :label="$t('snapshots.select_thumbnail', 'Select Thumbnail')"
            accept="image/*"
            :multiple="false"
            @fileselected="onThumbnailSelected"
          />
        </div>

        <div class="field">
          <label class="label">{{ $t('snapshots.preview', 'Preview (Video)') }}</label>
          <file-upload
            ref="previewUpload"
            :label="$t('snapshots.select_preview', 'Select Preview')"
            accept="video/*"
            :multiple="false"
            @fileselected="onPreviewSelected"
          />
        </div>

        <div class="field">
          <label class="label">{{ $t('snapshots.message', 'Message') }}</label>
          <div class="control">
            <textarea
              class="textarea"
              v-model="form.message"
              :placeholder="$t('snapshots.message_placeholder', 'Enter a description...')"
            ></textarea>
          </div>
        </div>
        
        <p class="error has-text-danger" v-if="isError">
          {{ $t('snapshots.create_error', 'Error creating snapshot') }}
        </p>

        <div class="field is-grouped is-grouped-right mt-4">
          <div class="control">
             <button @click="$emit('cancel')" class="button">
              {{ $t('main.cancel', 'Cancel') }}
            </button>
          </div>
          <div class="control">
            <button
              class="button is-primary"
              :class="{ 'is-loading': isLoading }"
              @click="submitSnapshot"
              :disabled="isLoading"
            >
              {{ $t('snapshots.create_btn', 'Snapshot') }}
            </button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { modalMixin } from '@/components/modals/base_modal'
import FileUpload from '@/components/widgets/FileUpload.vue'

export default {
  name: 'create-snapshot-modal',

  mixins: [modalMixin],

  components: {
    FileUpload
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

  emits: ['cancel', 'confirm'],

  data() {
    return {
      form: {
        type: 'source',
        message: '',
        thumbnail: null,
        preview: null
      },
      isLoading: false,
      isError: false
    }
  },

  methods: {
    onThumbnailSelected(formData) {
      // FileUpload returns FormData, key is 'file' (or prop uploadFieldName)
      // modifying to extract file object for our main submission if needed, 
      // or we can just keep the file object.
      // FileUpload emits FormData array usually if multiple, assuming simple here.
      // Looking at FileUpload src: 
      // if multiple=false -> emits single FormData
      // FormData contains 'file' -> valid file
      // Effectively we need the File object to append to our final formData
      if (formData && formData.get) {
        this.form.thumbnail = formData.get('file')
      }
    },

    onPreviewSelected(formData) {
      if (formData && formData.get) {
        this.form.preview = formData.get('file')
      }
    },

    async submitSnapshot() {
      this.isLoading = true
      this.isError = false
      
      try {
        const formData = new FormData()
        formData.append('taskId', this.taskId)
        formData.append('type', this.form.type)
        formData.append('message', this.form.message)
        
        if (this.form.thumbnail) {
          formData.append('thumbnail', this.form.thumbnail)
        }
        
        if (this.form.preview) {
          formData.append('preview', this.form.preview)
        }

        const response = await fetch('/wekitsu-api/snapshot', {
          method: 'POST',
          body: formData
        })

        if (response.ok) {
          this.$emit('confirm')
          this.reset()
        } else {
          this.isError = true
          console.error('Snapshot creation failed')
        }
      } catch (e) {
        console.error('Error creating snapshot:', e)
        this.isError = true
      } finally {
        this.isLoading = false
      }
    },

    reset() {
      this.form = {
        type: 'source',
        message: '',
        thumbnail: null,
        preview: null
      }
      this.isError = false
      this.isLoading = false
      // Reset file inputs
      if (this.$refs.thumbnailUpload) this.$refs.thumbnailUpload.reset()
      if (this.$refs.previewUpload) this.$refs.previewUpload.reset()
    }
  },

  watch: {
    active(newVal) {
      if (newVal) {
        this.reset()
      }
    }
  }
}
</script>

<style lang="scss" scoped>
.modal-content {
  width: 600px;
}
</style>
