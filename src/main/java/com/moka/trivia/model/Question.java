package com.moka.trivia.model;

import jakarta.persistence.*;

@Entity
public class Question {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;            // מפתח ראשי רץ אוטומטית

    private String question;    // הטקסט של השאלה
    private String answer;      // התשובה
    private String explanation; // הרחבה

    @ManyToOne
    @JoinColumn(name = "category_id", nullable = false) // foreign key לקטגוריה
    private Category category;

    // --- בנאים (constructors) ---
    public Question() {}

    public Question(String question, String answer, String explanation, Category category) {
        this.question = question;
        this.answer = answer;
        this.explanation = explanation;
        this.category = category;
    }

    // --- getters & setters ---
    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getQuestion() {
        return question;
    }

    public void setQuestion(String question) {
        this.question = question;
    }

    public String getAnswer() {
        return answer;
    }

    public void setAnswer(String answer) {
        this.answer = answer;
    }

    public String getExplanation() {
        return explanation;
    }

    public void setExplanation(String explanation) {
        this.explanation = explanation;
    }

    public Category getCategory() {
        return category;
    }

    public void setCategory(Category category) {
        this.category = category;
    }
}
