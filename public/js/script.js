// Configuration
const API_BASE_URL = 'http://127.0.0.1:8080';
let questions = [];
let answers = {};

// DOM Elements
const loadingEl = document.getElementById('loading');
const errorEl = document.getElementById('error');
const errorMessageEl = document.getElementById('error-message');
const retryBtn = document.getElementById('retry-btn');
const surveyForm = document.getElementById('survey-form');
const questionsContainer = document.getElementById('questions-container');
const progressFill = document.getElementById('progress-fill');
const answeredCountEl = document.getElementById('answered-count');
const totalQuestionsEl = document.getElementById('total-questions');
const submitBtn = document.getElementById('submit-btn');
const resetBtn = document.getElementById('reset-btn');
const successEl = document.getElementById('success');
const submittedCountEl = document.getElementById('submitted-count');
const totalStoredEl = document.getElementById('total-stored');
const newSurveyBtn = document.getElementById('new-survey-btn');
const statsQuestionsEl = document.getElementById('stats-questions');
const statsAnswersEl = document.getElementById('stats-answers');
const serverStatusEl = document.getElementById('server-status');
const statusDot = serverStatusEl.querySelector('.status-dot');
const statusText = serverStatusEl.querySelector('.status-text');

// Initialize application
document.addEventListener('DOMContentLoaded', () => {
    checkServerStatus();
    loadQuestions();
    setupEventListeners();
});

// Check if server is running
async function checkServerStatus() {
    try {
        const response = await fetch(`${API_BASE_URL}/health`, {
            method: 'GET',
            headers: { 'Accept': 'text/plain' }
        });
        
        if (response.ok) {
            statusDot.classList.add('connected');
            statusDot.classList.remove('disconnected');
            statusText.textContent = 'Connected';
            return true;
        } else {
            throw new Error('Server responded with error');
        }
    } catch (error) {
        statusDot.classList.add('disconnected');
        statusDot.classList.remove('connected');
        statusText.textContent = 'Disconnected';
        return false;
    }
}

// Load questions from API
async function loadQuestions() {
    try {
        showLoading();
        
        const response = await fetch(`${API_BASE_URL}/questions`);
        
        if (!response.ok) {
            throw new Error(`HTTP ${response.status}: ${response.statusText}`);
        }
        
        questions = await response.json();
        
        // Update stats
        statsQuestionsEl.textContent = questions.length;
        
        // Initialize answers object
        questions.forEach(question => {
            answers[question.id] = '';
        });
        
        renderQuestions();
        updateProgress();
        showForm();
        
        // Try to get current answer count
        updateAnswerStats();
        
    } catch (error) {
        console.error('Failed to load questions:', error);
        showError(`Failed to load questions: ${error.message}`);
    }
}

// Render questions to the form
function renderQuestions() {
    questionsContainer.innerHTML = '';
    
    questions.forEach((question, index) => {
        const questionEl = document.createElement('div');
        questionEl.className = `question-card ${question.type}`;
        questionEl.dataset.questionId = question.id;
        
        let optionsHtml = '';
        
        if (question.type === 'text') {
            optionsHtml = `
                <textarea 
                    class="text-input" 
                    placeholder="Type your answer here..."
                    rows="3"
                    data-question-id="${question.id}"
                >${answers[question.id] || ''}</textarea>
            `;
        } else if (question.options && question.options.length > 0) {
            const inputType = question.type === 'multipleChoice' ? 'checkbox' : 'radio';
            const name = question.type === 'multipleChoice' ? `question-${question.id}` : `question-${question.id}`;
            
            optionsHtml = '<div class="options-container">';
            question.options.forEach(option => {
                const isChecked = question.type === 'multipleChoice' 
                    ? (answers[question.id] && answers[question.id].includes(option))
                    : (answers[question.id] === option);
                    
                optionsHtml += `
                    <label class="option ${isChecked ? 'selected' : ''}">
                        <input 
                            type="${inputType}"
                            name="${name}"
                            value="${option}"
                            data-question-id="${question.id}"
                            ${isChecked ? 'checked' : ''}
                        >
                        <span class="option-label">${option}</span>
                    </label>
                `;
            });
            optionsHtml += '</div>';
        }
        
        questionEl.innerHTML = `
            <div class="question-header">
                <div class="question-text">
                    <span class="required">${question.text}</span>
                    <div class="question-type">${question.readableType}</div>
                </div>
                <div class="question-id">${index + 1}</div>
            </div>
            ${optionsHtml}
        `;
        
        questionsContainer.appendChild(questionEl);
    });
    
    // Add event listeners to inputs
    addInputEventListeners();
}

// Add event listeners to form inputs
function addInputEventListeners() {
    // Text inputs
    document.querySelectorAll('.text-input').forEach(input => {
        input.addEventListener('input', (e) => {
            const questionId = parseInt(e.target.dataset.questionId);
            answers[questionId] = e.target.value.trim();
            updateProgress();
        });
    });
    
    // Radio buttons
    document.querySelectorAll('input[type="radio"]').forEach(radio => {
        radio.addEventListener('change', (e) => {
            const questionId = parseInt(e.target.dataset.questionId);
            answers[questionId] = e.target.value;
            
            // Update visual selection
            document.querySelectorAll(`input[name="question-${questionId}"]`).forEach(input => {
                input.closest('.option').classList.toggle('selected', input.checked);
            });
            
            updateProgress();
        });
    });
    
    // Checkboxes
    document.querySelectorAll('input[type="checkbox"]').forEach(checkbox => {
        checkbox.addEventListener('change', (e) => {
            const questionId = parseInt(e.target.dataset.questionId);
            const checkedOptions = Array.from(
                document.querySelectorAll(`input[data-question-id="${questionId}"]:checked`)
            ).map(input => input.value);
            
            answers[questionId] = checkedOptions.join(', ');
            
            // Update visual selection
            e.target.closest('.option').classList.toggle('selected', e.target.checked);
            
            updateProgress();
        });
    });
}

// Update progress bar and counter
function updateProgress() {
    const total = questions.length;
    const answered = Object.values(answers).filter(answer => 
        answer && answer.toString().trim().length > 0
    ).length;
    
    const percentage = total > 0 ? (answered / total) * 100 : 0;
    
    progressFill.style.width = `${percentage}%`;
    answeredCountEl.textContent = answered;
    totalQuestionsEl.textContent = total;
    
    // Enable/disable submit button
    submitBtn.disabled = answered === 0;
}

// Update answer statistics
async function updateAnswerStats() {
    try {
        // Prefer server count stored in localStorage (updated after each submission)
        const serverCount = localStorage.getItem('serverTotalAnswersStored');
        if (serverCount !== null) {
            statsAnswersEl.textContent = serverCount;
            return;
        }
        
        // Fallback: estimate based on local storage keys
        const storedCount = Object.keys(localStorage).filter(key =>
            key.startsWith('survey_answer_')
        ).length;
        
        statsAnswersEl.textContent = storedCount > 0 ? storedCount : '0';
    } catch (error) {
        console.error('Failed to update answer stats:', error);
    }
}

// Show loading state
function showLoading() {
    loadingEl.style.display = 'block';
    errorEl.style.display = 'none';
    surveyForm.style.display = 'none';
    successEl.style.display = 'none';
}

// Show error state
function showError(message) {
    loadingEl.style.display = 'none';
    errorEl.style.display = 'block';
    errorMessageEl.textContent = message;
    surveyForm.style.display = 'none';
    successEl.style.display = 'none';
}

// Show form
function showForm() {
    loadingEl.style.display = 'none';
    errorEl.style.display = 'none';
    surveyForm.style.display = 'flex';
    successEl.style.display = 'none';
    
    // Reset submit button to original state
    submitBtn.innerHTML = '<i class="fas fa-paper-plane"></i> Submit Answers';
    // Disabled state will be updated by updateProgress()
}

// Show success state
function showSuccess(response) {
    loadingEl.style.display = 'none';
    errorEl.style.display = 'none';
    surveyForm.style.display = 'none';
    successEl.style.display = 'block';
    
    submittedCountEl.textContent = response.receivedCount || 0;
    totalStoredEl.textContent = response.totalAnswersStored || 0;
    
    // Update stats
    statsAnswersEl.textContent = response.totalAnswersStored || 0;
    
    // Store server count in localStorage for consistency
    localStorage.setItem('serverTotalAnswersStored', response.totalAnswersStored.toString());
}

// Setup event listeners
function setupEventListeners() {
    // Retry button
    retryBtn.addEventListener('click', () => {
        loadQuestions();
    });
    
    // Reset button
    resetBtn.addEventListener('click', () => {
        if (confirm('Are you sure you want to reset all answers?')) {
            questions.forEach(question => {
                answers[question.id] = '';
            });
            // Reset submit button to original state
            submitBtn.innerHTML = '<i class="fas fa-paper-plane"></i> Submit Answers';
            renderQuestions();
            updateProgress();
        }
    });
    
    // Form submission
    surveyForm.addEventListener('submit', async (e) => {
        e.preventDefault();
        
        // Prepare answers for submission
        const answerSubmissions = [];
        
        questions.forEach(question => {
            const answer = answers[question.id];
            if (answer && answer.toString().trim().length > 0) {
                answerSubmissions.push({
                    questionId: question.id,
                    answer: answer.toString()
                });
            }
        });
        
        if (answerSubmissions.length === 0) {
            alert('Please answer at least one question before submitting.');
            return;
        }
        
        try {
            submitBtn.disabled = true;
            submitBtn.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Submitting...';
            
            const response = await fetch(`${API_BASE_URL}/answers`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({
                    answers: answerSubmissions
                })
            });
            
            if (!response.ok) {
                const errorText = await response.text();
                throw new Error(`Submission failed: ${errorText}`);
            }
            
            const result = await response.json();
            
            // Store in local storage for demo purposes
            answerSubmissions.forEach(answer => {
                localStorage.setItem(`survey_answer_${Date.now()}_${answer.questionId}`, answer.answer);
            });
            
            showSuccess(result);
            
        } catch (error) {
            console.error('Submission error:', error);
            alert(`Failed to submit answers: ${error.message}`);
            
            submitBtn.disabled = false;
            submitBtn.innerHTML = '<i class="fas fa-paper-plane"></i> Submit Answers';
        }
    });
    
    // New survey button
    newSurveyBtn.addEventListener('click', () => {
        // Reset answers
        questions.forEach(question => {
            answers[question.id] = '';
        });
        
        // Reset submit button to original state
        submitBtn.innerHTML = '<i class="fas fa-paper-plane"></i> Submit Answers';
        submitBtn.disabled = true; // Will be updated by updateProgress anyway
        
        renderQuestions();
        updateProgress();
        showForm();
    });
}

// Export for debugging
window.surveyApp = {
    questions,
    answers,
    loadQuestions,
    updateProgress,
    checkServerStatus
};