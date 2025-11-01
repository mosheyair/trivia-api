package com.moka.trivia.controller;

import com.moka.trivia.model.Category;
import com.moka.trivia.repository.CategoryRepository;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
@RequestMapping("/api/categories")
@CrossOrigin(origins = {"https://www.mokafullstack.com","https://api.mokafullstack.com"})
public class CategoryController {

    private final CategoryRepository repo;

    public CategoryController(CategoryRepository repo) {
        this.repo = repo;
    }

    @GetMapping
    public List<Category> all() {
        return repo.findAll();
    }
    @GetMapping("/test-db")
    public String testDB() {
        return "Database connection is working!";
    }

    @PostMapping
    public Category addCategory(@RequestBody Category category) {
        return repo.save(category);
    }


}


