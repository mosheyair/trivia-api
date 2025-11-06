package com.moka.trivia.controller;

import com.moka.trivia.model.Question;
import com.moka.trivia.repository.QuestionRepository;
import org.springframework.http.ResponseEntity; // ✅ חדש
import org.springframework.web.bind.annotation.*;

import java.util.List; // ✅ חדש

@RestController
@RequestMapping("/api/questions")
@CrossOrigin(origins = {"https://www.mokafullstack.com","https://api.mokafullstack.com"})
public class QuestionController {

    private final QuestionRepository repo;

    public QuestionController(QuestionRepository repo) {
        this.repo = repo;
    }

    @GetMapping
    public List<Question> list(@RequestParam(required = false) Long categoryId) {
        if (categoryId == null) {
            throw new IllegalArgumentException("Category ID is required to start the game.");
        }
        return repo.findByCategoryId(categoryId);
    }

    @PostMapping
    public ResponseEntity<Question> addQuestion(@RequestBody Question question) {
        Question saved = repo.save(question);
        return ResponseEntity.ok(saved);
    }
}
