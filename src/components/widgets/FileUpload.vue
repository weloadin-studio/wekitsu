<template>
  <div
    ref="wrapper"
    @drop="onDrop"
    @dragover="onDragover"
    @dragleave="onDragleave"
  >
    <form enctype="multipart/form-data" novalidate>
      <div 
        class="dropbox" 
        :class="{ 'is-dragging': isDragging }"
      >
        <label
          :class="{
            button: true,
            'is-primary': isPrimary
          }"
        >
          {{ label }}
          <input
            ref="uploadInput"
            class="visuallyhidden"
            type="file"
            :accept="accept"
            :name="uploadFieldName"
            :disabled="isSaving || disabled"
            :multiple="multiple"
            @change="filesChange($event.target.name, $event.target.files)"
          />
        </label>
        <span
          class="file-upload-status"
          v-if="uploadedFiles.length > 1 && !hideFileNames"
        >
          {{ uploadedFiles.length }} {{ $tc('main.files_selected') }}
        </span>
        <span
          class="file-upload-status"
          v-if="uploadedFiles.length === 1 && !hideFileNames"
        >
          {{ uploadedFiles[0] }}
        </span>
      </div>
    </form>
  </div>
</template>

<script>
export default {
  name: 'file-upload',

  props: {
    accept: {
      default: '.csv',
      type: String
    },
    isPrimary: {
      default: true,
      type: Boolean
    },
    label: {
      type: String,
      required: true
    },
    multiple: {
      default: false,
      type: Boolean
    },
    uploadFieldName: {
      default: 'file',
      type: String
    },
    disabled: {
      type: Boolean,
      default: false
    },
    hideFileNames: {
      type: Boolean,
      default: false
    }
  },

  emits: ['fileselected'],

  data() {
    return {
      isInitial: true,
      isSaving: false,
      isDragging: false,
      uploadedFiles: []
    }
  },

  mounted() {
    this.reset()
    const events = [
      'drag',
      'dragstart',
      'dragend',
      'dragover',
      'dragenter',
      'dragleave',
      'drop'
    ]
    events.forEach(evt => {
      this.$refs.wrapper.addEventListener(evt, e => {
        e.preventDefault()
        e.stopPropagation()
      })
    })
  },

  methods: {
    filesChange(name, files) {
      if (files.length === 0) return

      this.uploadedFiles = []
      const forms = []
      for (let i = 0, numFiles = files.length; i < numFiles; i++) {
        const file = files[i]
        const formData = new FormData()
        formData.append(this.uploadFieldName, file, file.name)
        forms.push(formData)
        if (this.multiple) {
          this.uploadedFiles.push(file.name)
        } else {
          this.uploadedFiles = [file.name]
        }
      }
      if (this.multiple) {
        this.$emit('fileselected', forms, files)
      } else {
        this.$emit('fileselected', forms[0], files[0])
      }
    },

    reset() {
      this.isSaving = false
      this.isInitial = true
      this.isDragging = false
      this.uploadedFiles = []
      if (this.$refs.uploadInput) {
        this.$refs.uploadInput.value = ''
      }
    },

    onDragover() {
      this.isDragging = true
    },

    onDragleave() {
      this.isDragging = false
    },

    onDrop(event) {
      this.isDragging = false
      if (event.dataTransfer.files) {
        this.isSaving = false
        this.filesChange('file', event.dataTransfer.files)
      }
    }
  }
}
</script>

<style lang="scss" scoped>
.dropbox {
  display: flex;
  align-items: center;
  justify-content: center;
  border: 2px dashed #dbdbdb;
  padding: 20px;
  border-radius: 6px;
  background-color: transparent;
  transition: all 0.2s ease;
  min-height: 80px;

  &.is-dragging {
    background-color: rgba(0, 0, 0, 0.05);
    border-color: #00d1b2; /* Bulma primary */
  }
}

:global(.dark) .dropbox {
  border-color: #40444b;
  &.is-dragging {
    background-color: rgba(255, 255, 255, 0.05);
    border-color: #7289da;
  }
}

.visuallyhidden {
  border: 0;
  clip: rect(0 0 0 0);
  height: 1px;
  margin: -1px;
  overflow: hidden;
  padding: 0;
  position: absolute;
  width: 1px;
}

.file-upload-status {
  margin-left: 1rem;
  font-style: italic;
  font-weight: 500;
  word-break: break-all;
}
</style>

